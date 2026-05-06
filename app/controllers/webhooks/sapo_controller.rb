# Webhook controller for Sapo order update events.
# Sapo sends HMAC-signed POST when orders/updated fires.
class Webhooks::SapoController < ActionController::API
  before_action :verify_hmac!

  def events
    order_id = params[:id]&.to_s
    return head :ok if order_id.blank?

    ConversationOrders::WebhookSyncJob.perform_later(platform: 'sapo', external_order_id: order_id)
    head :ok
  end

  private

  def verify_hmac!
    secret = GlobalConfigService.load('SAPO_WEBHOOK_SECRET', nil)
    return if secret.blank?

    data = request.body.read
    request.body.rewind

    hmac_header = request.headers['X-Sapo-Hmac-SHA256']
    return head :unauthorized if hmac_header.blank?

    computed = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, data))
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(computed, hmac_header)
  end
end
