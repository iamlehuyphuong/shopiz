# Webhook controller for KiotViet order update events.
# KiotViet sends POST with order data when OrderUpdated event fires.
class Webhooks::KiotvietController < ActionController::API
  before_action :verify_webhook!

  def events
    order_id = params.dig(:Data, :Id)&.to_s
    return head :ok if order_id.blank?

    ConversationOrders::WebhookSyncJob.perform_later(platform: 'kiotviet', external_order_id: order_id)
    head :ok
  end

  private

  def verify_webhook!
    # KiotViet webhook uses a shared secret configured in the store settings.
    # The webhook_secret is stored in the integration hook settings.
    webhook_secret = GlobalConfigService.load('KIOTVIET_WEBHOOK_SECRET', nil)
    return if webhook_secret.blank? # Skip verification if not configured

    token = request.headers['X-Webhook-Secret'] || params[:webhookSecret]
    return head :unauthorized unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, webhook_secret)
  end
end
