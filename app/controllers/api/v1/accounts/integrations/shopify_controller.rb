class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::BaseController
  include Shopify::IntegrationHelper
  before_action :setup_shopify_context, only: [:orders]
  before_action :fetch_hook, except: [:auth]
  before_action :validate_contact, only: [:orders]

  def auth
    shop_domain = params[:shop_domain]
    return render json: { error: 'Shop domain is required' }, status: :unprocessable_entity if shop_domain.blank?

    state = generate_shopify_token(Current.account.id)

    auth_url = "https://#{shop_domain}/admin/oauth/authorize?"
    auth_url += URI.encode_www_form(
      client_id: client_id,
      scope: REQUIRED_SCOPES.join(','),
      redirect_uri: redirect_uri,
      state: state
    )

    render json: { redirect_url: auth_url }
  end

  def orders
    customers = fetch_customers
    return render json: { orders: [] } if customers.empty?

    orders = fetch_orders({
                            customer_id: customers.first['id']
                          })
    render json: { orders: orders }
  rescue ShopifyAPI::Errors::HttpResponseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def all_orders
    orders = fetch_orders({})
    render json: { orders: orders }
  rescue ShopifyAPI::Errors::HttpResponseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def customers
    customers = fetch_customers
    render json: { customers: customers }
  rescue ShopifyAPI::Errors::HttpResponseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    products = fetch_products
    return render json: { products: [] } if products.empty?

    render json: { products: products }
  rescue ShopifyAPI::Errors::HttpResponseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def redirect_uri
    "#{ENV.fetch('FRONTEND_URL', '')}/shopify/callback"
  end

  def contact
    @contact ||= Current.account.contacts.find_by(id: params[:contact_id])
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'shopify')
  end

  def fetch_customers
    query = []
    query << "email:#{contact.email}" if contact.email.present?
    query << "phone:#{contact.phone_number}" if contact.phone_number.present?

    shopify_client.get(
      path: 'customers/search.json',
      query: {
        query: query.join(' OR '),
        fields: 'id,email,phone'
      }
    ).body['customers'] || []
  end

  def fetch_orders(filters)
    query = {
      status: 'any',
      fields: 'id,email,created_at,total_price,currency,fulfillment_status,financial_status'
    }.merge(filters.is_a?(Hash) ? filters : {})

    orders = shopify_client.get(
      path: 'orders.json',
      query: query
    ).body['orders'] || []

    orders.map do |order|
      order.merge('admin_url' => "https://#{@hook.reference_id}/admin/orders/#{order['id']}")
    end
  end

  def fetch_products
    products = shopify_client.get(
      path: 'products.json'
    ).body['products'] || []

    products.map do |product|
      total_stock = product['variants'].sum { |variant| variant['inventory_quantity'].to_i }
      stock_status =
        if total_stock > 5
          'In Stock'
        elsif total_stock > 0
          'Low Stock'
        else
          'Out Of Stock'
        end
      product.merge('stock' => total_stock, 'stock_status' => stock_status)
    end
  end

  def setup_shopify_context
    return if client_id.blank? || client_secret.blank?

    ShopifyAPI::Context.setup(
      api_key: client_id,
      api_secret_key: client_secret,
      api_version: '2025-01'.freeze,
      scope: REQUIRED_SCOPES.join(','),
      is_embedded: true,
      is_private: false
    )
  end

  def shopify_session
    ShopifyAPI::Auth::Session.new(shop: @hook.reference_id, access_token: @hook.access_token)
  end

  def shopify_client
    @shopify_client ||= ShopifyAPI::Clients::Rest::Admin.new(session: shopify_session)
  end

  def validate_contact
    return unless contact.blank? || (contact.email.blank? && contact.phone_number.blank?)

    render json: { error: 'Contact information missing' },
           status: :unprocessable_entity
  end
end
