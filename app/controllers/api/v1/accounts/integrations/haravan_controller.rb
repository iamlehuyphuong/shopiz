# API controller for Haravan integration.
# Haravan (Private App) uses a permanent Bearer API key — no OAuth redirect needed.
class Api::V1::Accounts::Integrations::HaravanController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:auth]

  def auth
    validate_auth_params!

    hook = create_or_update_hook
    render json: { status: 'connected', hook_id: hook.id }
  end

  def orders
    customer_id = find_customer_id
    return render json: { orders: [] } if customer_id.nil?

    result = haravan_get('orders.json', { customer_id: customer_id, status: 'any', limit: 20 })
    render json: { orders: result&.dig('orders') || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    result = haravan_get('products.json', { limit: 50 })
    render json: { products: result&.dig('products') || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def customers
    result = haravan_get('customers.json', { limit: 20 })
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
    raise ActionController::ParameterMissing, :api_key if params[:api_key].blank?
    raise ActionController::ParameterMissing, :store_name if params[:store_name].blank?
  end

  def create_or_update_hook
    hook = Integrations::Hook.find_or_initialize_by(account: Current.account, app_id: 'haravan')
    hook.update!(
      access_token: params[:api_key],
      reference_id: params[:store_name],
      settings: {
        'store_name' => params[:store_name]
      }
    )
    hook
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'haravan')
  end

  def find_customer_id
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return nil if contact.blank?

    query = contact.email.presence || contact.phone_number
    return nil if query.blank?

    result = haravan_get('customers/search.json', { query: query })
    result&.dig('customers')&.first&.dig('id')
  end

  def haravan_get(endpoint, params = {})
    response = Faraday.get("https://apis.haravan.com/com/#{endpoint}") do |req|
      req.headers['Authorization'] = "Bearer #{@hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  end
end
