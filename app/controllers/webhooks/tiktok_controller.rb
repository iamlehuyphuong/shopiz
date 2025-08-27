class Webhooks::TiktokController < ActionController::API
  def process_payload
    body = request.body.read

    unless verify_tiktok_signature(body, request.headers["TikTok-Signature"])
      render plain: "Unauthorized", status: :unauthorized and return
    end

    payload = JSON.parse(body) rescue nil
    return render plain: "Invalid JSON", status: :bad_request unless payload

    Rails.logger.info "Verified TikTok webhook event: #{payload}"
    Webhooks::TiktokMessagesJob.perform_later(payload)

    head :ok
  end

  private

  def verify_tiktok_signature(body, signature_header)
    return false if body.blank? || signature_header.blank?

    timestamp = signature_header.split(",").find { |s| s.start_with?("t=") }&.split("=")&.last
    signature_value = signature_header.split(",").find { |s| s.start_with?("s=") }&.split("=")&.last
    return false unless timestamp && signature_value

    payload = "#{timestamp}.#{body}"
    app_secret = GlobalConfigService.load('TIKTOK_APP_SECRET', '')
    expected_signature = OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload)

    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature_value)
  end
end
