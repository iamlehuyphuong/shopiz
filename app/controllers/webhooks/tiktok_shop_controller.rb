class Webhooks::TiktokShopController < ActionController::API
  def process_payload
    body = request.raw_post

    render plain: 'Unauthorized', status: :unauthorized and return unless verify_tiktok_signature(body, request.headers['TikTok-Signature'])

    payload = begin
      JSON.parse(body)
    rescue StandardError
      nil
    end
    return render plain: 'Invalid JSON', status: :bad_request unless payload

    Rails.logger.info "Verified TikTok webhook event: #{payload}"
    dispatch_event(payload)

    head :ok
  end

  private

  def verify_tiktok_signature(body, signature_header)
    return false if body.blank? || signature_header.blank?

    timestamp = signature_header.split(',').find { |s| s.start_with?('t=') }&.split('=')&.last
    signature_value = signature_header.split(',').find { |s| s.start_with?('s=') }&.split('=')&.last
    return false unless timestamp && signature_value

    payload = "#{timestamp}.#{body}"
    app_secret = GlobalConfigService.load('TIKTOK_SHOP_APP_SECRET', '')
    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', app_secret, payload)

    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature_value)
  end

  def dispatch_event(payload)
    event_type = payload['type']

    case event_type
    when 5 # Order events (ORDER_STATUS_CHANGE, etc.)
      handle_order_event(payload)
    else # type 14 = messages, and all others
      Webhooks::TiktokShopMessagesJob.perform_later(payload)
    end
  end

  def handle_order_event(payload)
    order_id = payload.dig('data', 'order_id')&.to_s
    return if order_id.blank?

    ConversationOrders::WebhookSyncJob.perform_later(platform: 'tiktok_shop', external_order_id: order_id)
  end
end
