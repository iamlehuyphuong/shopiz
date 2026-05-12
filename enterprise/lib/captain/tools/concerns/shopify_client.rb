module Captain::Tools::Concerns::ShopifyClient
  extend ActiveSupport::Concern

  private

  def shopify_hook
    @shopify_hook ||= begin
      if respond_to?(:conversation) && conversation
        hook = conversation.inbox&.effective_ecommerce_hook
        return hook if hook&.app_id == 'shopify'
      end
      Integrations::Hook.find_by(account_id: @assistant.account_id, app_id: 'shopify')
    end
  end

  def shopify_active?
    shopify_hook.present? && shopify_hook.access_token.present?
  end

  def setup_shopify_context
    client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
    return if client_id.blank? || client_secret.blank?

    ShopifyAPI::Context.setup(
      api_key: client_id,
      api_secret_key: client_secret,
      api_version: '2025-01'.freeze,
      scope: 'read_products,read_customers,read_orders,read_fulfillments,write_orders,write_customers',
      is_embedded: true,
      is_private: false
    )
  end

  def shopify_client
    @shopify_client ||= begin
      setup_shopify_context
      session = ShopifyAPI::Auth::Session.new(shop: shopify_hook.reference_id, access_token: shopify_hook.access_token)
      ShopifyAPI::Clients::Rest::Admin.new(session: session)
    end
  end

  def shopify_get(path, query = {})
    shopify_client.get(path: path, query: query).body
  rescue ShopifyAPI::Errors::HttpResponseError => e
    Rails.logger.error("Shopify API error: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Shopify client error: #{e.message}")
    nil
  end

  def shopify_post(path, body = {})
    shopify_client.post(path: path, body: body).body
  rescue ShopifyAPI::Errors::HttpResponseError => e
    Rails.logger.error("Shopify API POST error: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Shopify POST error: #{e.message}")
    nil
  end

  def shopify_put(path, body = {})
    shopify_client.put(path: path, body: body).body
  rescue ShopifyAPI::Errors::HttpResponseError => e
    Rails.logger.error("Shopify API PUT error: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Shopify PUT error: #{e.message}")
    nil
  end

  def format_currency(amount, currency)
    "#{amount} #{currency || 'USD'}"
  end
end
