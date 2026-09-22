# Shared concern for KiotViet API access across Captain tools.
# Handles authentication (OAuth2 client_credentials), on-demand token refresh,
# and HTTP requests to https://public.kiotapi.com.
module Captain::Tools::Kiotviet::Client
  extend ActiveSupport::Concern

  KIOTVIET_API_BASE = 'https://public.kiotapi.com'.freeze
  KIOTVIET_TOKEN_URL = 'https://id.kiotviet.vn/connect/token'.freeze

  private

  def kiotviet_hook
    @kiotviet_hook ||= Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'kiotviet')
  end

  def kiotviet_active?
    kiotviet_hook.present? && kiotviet_hook.merged_settings['access_token'].present?
  end

  def kiotviet_get(endpoint, params = {})
    ensure_valid_token
    response = kiotviet_connection.get(endpoint) do |req|
      req.headers.merge!(kiotviet_headers)
      req.params.merge!(params) if params.present?
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("KiotViet API error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("KiotViet JSON parse error: #{e.message}")
    nil
  end

  def kiotviet_post(endpoint, body = {})
    ensure_valid_token
    response = kiotviet_connection.post(endpoint) do |req|
      req.headers.merge!(kiotviet_headers)
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("KiotViet API POST error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("KiotViet JSON parse error: #{e.message}")
    nil
  end

  def kiotviet_put(endpoint, body = {})
    ensure_valid_token
    response = kiotviet_connection.put(endpoint) do |req|
      req.headers.merge!(kiotviet_headers)
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("KiotViet API PUT error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("KiotViet JSON parse error: #{e.message}")
    nil
  end

  def kiotviet_connection
    @kiotviet_connection ||= Faraday.new(url: KIOTVIET_API_BASE) do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
  end

  def kiotviet_headers
    {
      'Retailer' => kiotviet_hook.merged_settings['retailer'],
      'Authorization' => "Bearer #{kiotviet_hook.merged_settings['access_token']}",
      'Content-Type' => 'application/json',
      'Accept-Encoding' => 'identity'
    }
  end

  def ensure_valid_token
    return if token_valid?

    refresh_token
  end

  def token_valid?
    expires_at = kiotviet_hook.merged_settings&.dig('token_expires_at')
    return false if expires_at.blank?

    Time.zone.parse(expires_at.to_s) > Time.current
  end

  def refresh_token
    settings = kiotviet_hook.merged_settings || {}
    response = request_new_token(settings['client_id'], settings['client_secret'])
    return if response.nil?

    parsed = JSON.parse(response.body)
    return if parsed['access_token'].blank?

    update_hook_token(parsed)
  end

  def request_new_token(client_id, client_secret)
    Faraday.post(KIOTVIET_TOKEN_URL) do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        scopes: 'PublicApi.Access',
        grant_type: 'client_credentials',
        client_id: client_id,
        client_secret: client_secret
      )
    end
  rescue Faraday::Error => e
    Rails.logger.error("KiotViet token refresh error: #{e.message}")
    nil
  end

  def update_hook_token(parsed)
    expires_at = Time.current + parsed['expires_in'].to_i.seconds
    kiotviet_hook.update!(
      settings: kiotviet_hook.settings.merge(
        'access_token' => parsed['access_token'],
        'token_expires_at' => expires_at.iso8601
      )
    )
    @kiotviet_hook = nil # bust cache
  end

  def format_currency(amount)
    return '0 VND' if amount.blank?

    "#{amount} VND"
  end
end
