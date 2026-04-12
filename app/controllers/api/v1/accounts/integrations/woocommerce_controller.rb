# API controller for WooCommerce (WordPress) integration.
# Uses HTTP Basic Auth with consumer_key:consumer_secret — no token refresh needed.
class Api::V1::Accounts::Integrations::WoocommerceController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:auth]

  def auth
    validate_auth_params!

    unless verify_connection
      return render json: { error: 'Failed to connect to WooCommerce. Check your credentials and store URL.' },
                    status: :unprocessable_entity
    end

    hook = create_or_update_hook
    render json: { status: 'connected', hook_id: hook.id }
  end

  def orders
    result = woo_get('orders', { per_page: 20, orderby: 'date', order: 'desc' })
    render json: { orders: result.is_a?(Array) ? result : [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    result = woo_get('products', { per_page: 50, status: 'publish' })
    render json: { products: result.is_a?(Array) ? result : [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def customers
    result = woo_get('customers', { per_page: 20 })
    render json: { customers: result.is_a?(Array) ? result : [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def validate_auth_params!
    %i[store_url consumer_key consumer_secret].each do |key|
      raise ActionController::ParameterMissing, key if params[key].blank?
    end
  end

  def verify_connection
    conn = build_connection(params[:store_url], params[:consumer_key], params[:consumer_secret])
    response = conn.get('system_status')
    response.status == 200
  rescue StandardError => e
    Rails.logger.error("WooCommerce connection verify error: #{e.message}")
    false
  end

  def create_or_update_hook
    hook = Integrations::Hook.find_or_initialize_by(account: Current.account, app_id: 'woocommerce')
    hook.update!(
      access_token: nil,
      reference_id: params[:store_url],
      settings: {
        'store_url' => params[:store_url],
        'consumer_key' => params[:consumer_key],
        'consumer_secret' => params[:consumer_secret]
      }
    )
    hook
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'woocommerce')
  end

  def woo_get(endpoint, params = {})
    response = woo_connection.get(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  end

  def woo_connection
    @woo_connection ||= build_connection(
      @hook.reference_id,
      @hook.settings['consumer_key'],
      @hook.settings['consumer_secret']
    )
  end

  def build_connection(store_url, consumer_key, consumer_secret)
    Faraday.new(url: "https://#{store_url}/wp-json/wc/v3") do |f|
      f.request :authorization, :basic, consumer_key, consumer_secret
      f.adapter Faraday.default_adapter
    end
  end
end
