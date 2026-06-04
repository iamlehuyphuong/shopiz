# Webhook controller for WooCommerce order update events.
# WooCommerce sends HMAC-signed POST via X-WC-Webhook-Signature header.
class Webhooks::WoocommerceController < ActionController::API
  before_action :verify_hmac!

  def events
    order_id = params[:id]&.to_s
    return head :ok if order_id.blank?

    ConversationOrders::WebhookSyncJob.perform_later(platform: 'woocommerce', external_order_id: order_id)
    head :ok
  end

  private

  def verify_hmac!
    secret = GlobalConfigService.load('WOOCOMMERCE_WEBHOOK_SECRET', nil)
    if secret.blank?
      Rails.logger.warn('Webhooks::WoocommerceController: WOOCOMMERCE_WEBHOOK_SECRET not configured, rejecting webhook')
      return head :unauthorized
    end

    data = request.body.read
    request.body.rewind

    signature = request.headers['X-WC-Webhook-Signature']
    return head :unauthorized if signature.blank?

    computed = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, data))
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(computed, signature)
  end
end
