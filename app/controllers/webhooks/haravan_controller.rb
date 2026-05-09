# Webhook controller for Haravan order update events.
# Haravan sends HMAC-signed POST via X-Haravan-Hmacsha256 header.
class Webhooks::HaravanController < ActionController::API
  before_action :verify_hmac!

  def events
    order_id = params[:id]&.to_s
    return head :ok if order_id.blank?

    ConversationOrders::WebhookSyncJob.perform_later(platform: 'haravan', external_order_id: order_id)
    head :ok
  end

  private

  def verify_hmac!
    secret = GlobalConfigService.load('HARAVAN_WEBHOOK_SECRET', nil)
    if secret.blank?
      Rails.logger.warn('Webhooks::HaravanController: HARAVAN_WEBHOOK_SECRET not configured, rejecting webhook')
      return head :unauthorized
    end

    data = request.body.read
    request.body.rewind

    hmac_header = request.headers['X-Haravan-Hmacsha256']
    return head :unauthorized if hmac_header.blank?

    computed = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, data))
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(computed, hmac_header)
  end
end
