# API controller for Sapo integration.
# Sapo uses X-Sapo-Access-Token header for authentication.
# Base URL: https://{store}.mysapo.net/admin/
class Api::V1::Accounts::Integrations::SapoController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:auth]

  def auth
    validate_auth_params!

    hook = create_or_update_hook
    render json: { status: 'connected', hook_id: hook.id }
  end

  def orders
    customer_id = find_customer_id
    return render json: { orders: [] } if customer_id.nil?

    result = sapo_get('orders.json', { customer_id: customer_id, status: 'any', limit: 20 })
    render json: { orders: result&.dig('orders') || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    result = sapo_get('products.json', { limit: 50 })
    render json: { products: result&.dig('products') || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def customers
    result = sapo_get('customers.json', { limit: 20 })
    render json: { customers: result&.dig('customers') || [] }
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
    raise ActionController::ParameterMissing, :access_token if params[:access_token].blank?
    raise ActionController::ParameterMissing, :store_name if params[:store_name].blank?
  end

  def create_or_update_hook
    hook = Integrations::Hook.find_or_initialize_by(account: Current.account, app_id: 'sapo')
    hook.update!(
      access_token: params[:access_token],
      reference_id: params[:store_name],
      settings: {
        'store_name' => params[:store_name]
      }
    )
    hook
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'sapo')
  end

  def find_customer_id
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return nil if contact.blank?

    query = contact.email.presence || contact.phone_number
    return nil if query.blank?

    result = sapo_get('customers/search.json', { query: query })
    result&.dig('customers')&.first&.dig('id')
  end

  def sapo_get(endpoint, params = {})
    store_name = @hook.settings&.dig('store_name') || @hook.reference_id
    response = Faraday.get("https://#{store_name}.mysapo.net/admin/#{endpoint}") do |req|
      req.headers['X-Sapo-Access-Token'] = @hook.access_token
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  end
end
