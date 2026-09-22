# Shared concern for Haravan API access across Captain tools.
# Haravan uses Bearer token (Private App API key) — no token refresh needed.
# Base URL: https://apis.haravan.com/com/
module Captain::Tools::Haravan::Client
  extend ActiveSupport::Concern

  HARAVAN_API_BASE = 'https://apis.haravan.com/com'.freeze

  private

  def haravan_hook
    @haravan_hook ||= Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'haravan')
  end

  def haravan_active?
    haravan_hook.present? && haravan_hook.access_token.present?
  end

  def haravan_get(endpoint, params = {})
    response = haravan_connection.get(endpoint) do |req|
      req.headers['Authorization'] = "Bearer #{haravan_hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("Haravan API error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Haravan JSON parse error: #{e.message}")
    nil
  end

  def haravan_post(endpoint, body = {})
    response = haravan_connection.post(endpoint) do |req|
      req.headers['Authorization'] = "Bearer #{haravan_hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("Haravan API POST error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Haravan JSON parse error: #{e.message}")
    nil
  end

  def haravan_put(endpoint, body = {})
    response = haravan_connection.put(endpoint) do |req|
      req.headers['Authorization'] = "Bearer #{haravan_hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("Haravan API PUT error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Haravan JSON parse error: #{e.message}")
    nil
  end

  def haravan_connection
    @haravan_connection ||= Faraday.new(url: HARAVAN_API_BASE) do |f|
      f.adapter Faraday.default_adapter
    end
  end

  def format_currency(amount, currency = 'VND')
    "#{amount} #{currency}"
  end
end
