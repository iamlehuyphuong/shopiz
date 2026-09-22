# Shared concern for TikTok Shop Open API access across Captain tools.
# Base URL: https://open-api.tiktokglobalshop.com
module Captain::Tools::TiktokShop::Client
  extend ActiveSupport::Concern

  TIKTOK_SHOP_API_BASE = 'https://open-api.tiktokglobalshop.com'.freeze

  private

  def tiktok_shop_hook
    @tiktok_shop_hook ||= Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'tiktok_shop')
  end

  def tiktok_shop_active?
    tiktok_shop_hook.present? && tiktok_shop_hook.access_token.present? && tiktok_shop_hook.settings&.dig('shop_cipher').present?
  end

  def tiktok_shop_app_key
    GlobalConfigService.load('TIKTOK_SHOP_APP_KEY', '')
  end

  def tiktok_shop_default_params
    {
      app_key: tiktok_shop_app_key,
      shop_cipher: tiktok_shop_hook.settings['shop_cipher'],
      timestamp: Time.now.to_i
    }
  end

  def tiktok_shop_headers
    {
      'Content-Type' => 'application/json',
      'x-tts-access-token' => tiktok_shop_hook.access_token
    }
  end

  def tiktok_shop_get(endpoint, params = {})
    url = "#{TIKTOK_SHOP_API_BASE}#{endpoint}"
    signed_url = ::TiktokShop::SignatureService.signed_url(
      url,
      params: tiktok_shop_default_params.merge(params),
      content_type: 'application/json'
    )

    response = HTTParty.get(signed_url, headers: tiktok_shop_headers)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("TikTok Shop API GET error: #{e.message}")
    nil
  end

  def tiktok_shop_post(endpoint, body = {})
    url = "#{TIKTOK_SHOP_API_BASE}#{endpoint}"
    payload = body.to_json
    signed_url = ::TiktokShop::SignatureService.signed_url(
      url,
      params: tiktok_shop_default_params,
      body: payload,
      content_type: 'application/json'
    )

    response = HTTParty.post(signed_url, headers: tiktok_shop_headers, body: payload)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("TikTok Shop API POST error: #{e.message}")
    nil
  end

  def format_currency(amount, currency = 'VND')
    "#{amount} #{currency}"
  end
end
