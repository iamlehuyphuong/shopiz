# Webhook controller for Nhanh.vn order update events.
# Nhanh.vn sends POST with Authorization header containing verify token.
class Webhooks::NhanhvnController < ActionController::API
  before_action :verify_token!

  def events
    event = params[:event]
    return head :ok unless %w[orderAdd orderUpdate].include?(event)

    order_id = params.dig(:data, :id)&.to_s
    return head :ok if order_id.blank?

    ConversationOrders::WebhookSyncJob.perform_later(platform: 'nhanhvn', external_order_id: order_id)
    head :ok
  end

  private

  def verify_token!
    verify_token = GlobalConfigService.load('NHANHVN_WEBHOOK_TOKEN', nil)
    if verify_token.blank?
      Rails.logger.warn('Webhooks::NhanhvnController: NHANHVN_WEBHOOK_TOKEN not configured, rejecting webhook')
      return head :unauthorized
    end

    auth_header = request.headers['Authorization']
    return head :unauthorized if auth_header.blank?
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(auth_header, verify_token)
  end
end
