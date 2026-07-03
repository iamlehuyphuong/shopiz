# Shared concern for Nhanh.vn API access across Captain tools.
# Handles authentication via appId + accessToken + businessId,
# and HTTP POST requests to https://open.nhanh.vn API v2.
module Captain::Tools::Concerns::NhanhvnClient
  extend ActiveSupport::Concern

  NHANHVN_API_BASE = 'https://open.nhanh.vn'.freeze

  private

  def nhanhvn_hook
    @nhanhvn_hook ||= Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'nhanhvn')
  end

  def nhanhvn_active?
    nhanhvn_hook.present? && nhanhvn_hook.access_token.present?
  end

  def nhanhvn_post(endpoint, data = {})
    response = nhanhvn_connection.post(endpoint) do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        version: '2.0',
        appId: nhanhvn_hook.settings['app_id'],
        businessId: nhanhvn_hook.settings['business_id'],
        accessToken: nhanhvn_hook.access_token,
        data: data.to_json
      )
    end
    parsed = JSON.parse(response.body)
    return parsed if parsed['code'] == 1

    Rails.logger.error("Nhanh.vn API error: #{parsed['messages']}")
    nil
  rescue Faraday::Error => e
    Rails.logger.error("Nhanh.vn API error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Nhanh.vn JSON parse error: #{e.message}")
    nil
  end

  def nhanhvn_connection
    @nhanhvn_connection ||= Faraday.new(url: NHANHVN_API_BASE) do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
  end

  def format_currency(amount)
    return '0 VND' if amount.blank?

    "#{amount} VND"
  end
end
