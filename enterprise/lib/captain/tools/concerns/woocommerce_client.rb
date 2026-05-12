# Shared concern for WooCommerce (WordPress) API access across Captain tools.
# Uses HTTP Basic Auth with consumer_key + consumer_secret.
# Base URL: https://{store_url}/wp-json/wc/v3/
module Captain::Tools::Concerns::WoocommerceClient
  extend ActiveSupport::Concern

  private

  def woocommerce_hook
    @woocommerce_hook ||= begin
      if respond_to?(:conversation) && conversation
        hook = conversation.inbox&.effective_ecommerce_hook
        return hook if hook&.app_id == 'woocommerce'
      end
      Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'woocommerce')
    end
  end

  def woocommerce_active?
    woocommerce_hook.present? && woocommerce_hook.settings&.dig('consumer_key').present?
  end

  def woocommerce_get(endpoint, params = {})
    response = woocommerce_connection.get(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("WooCommerce API error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("WooCommerce JSON parse error: #{e.message}")
    nil
  end

  def woocommerce_post(endpoint, body = {})
    response = woocommerce_connection.post(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("WooCommerce API POST error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("WooCommerce JSON parse error: #{e.message}")
    nil
  end

  def woocommerce_put(endpoint, body = {})
    response = woocommerce_connection.put(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    JSON.parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("WooCommerce API PUT error: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("WooCommerce JSON parse error: #{e.message}")
    nil
  end

  def woocommerce_connection
    @woocommerce_connection ||= begin
      store_url = woocommerce_hook.reference_id
      consumer_key = woocommerce_hook.settings['consumer_key']
      consumer_secret = woocommerce_hook.settings['consumer_secret']

      Faraday.new(url: "https://#{store_url}/wp-json/wc/v3") do |f|
        f.request :authorization, :basic, consumer_key, consumer_secret
        f.adapter Faraday.default_adapter
      end
    end
  end

  def format_woo_currency(amount, currency = 'USD')
    "#{amount} #{currency}"
  end
end
