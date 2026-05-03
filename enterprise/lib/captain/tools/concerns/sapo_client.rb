# Shared concern for Sapo API access across Captain tools.
# Sapo uses X-Sapo-Access-Token header — no token refresh needed.
# Base URL: https://{store}.mysapo.net/admin/
module Captain::Tools::Concerns::SapoClient
  extend ActiveSupport::Concern

  private

  def sapo_hook
    @sapo_hook ||= Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'sapo')
  end

  def sapo_active?
    sapo_hook.present? && sapo_hook.access_token.present?
  end

  def sapo_store_name
    sapo_hook.settings&.dig('store_name') || sapo_hook.reference_id
  end

  def sapo_get(endpoint, params = {})
    response = sapo_connection.get(endpoint) do |req|
      req.headers['X-Sapo-Access-Token'] = sapo_hook.access_token
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("Sapo API error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Sapo JSON parse error: #{e.message}")
    nil
  end

  def sapo_post(endpoint, body = {})
    response = sapo_connection.post(endpoint) do |req|
      req.headers['X-Sapo-Access-Token'] = sapo_hook.access_token
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("Sapo API POST error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Sapo JSON parse error: #{e.message}")
    nil
  end

  def sapo_put(endpoint, body = {})
    response = sapo_connection.put(endpoint) do |req|
      req.headers['X-Sapo-Access-Token'] = sapo_hook.access_token
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("Sapo API PUT error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("Sapo JSON parse error: #{e.message}")
    nil
  end

  def sapo_connection
    @sapo_connection ||= Faraday.new(url: "https://#{sapo_store_name}.mysapo.net/admin") do |f|
      f.adapter Faraday.default_adapter
    end
  end

  def format_sapo_currency(amount, currency = 'VND')
    "#{amount} #{currency}"
  end
end
