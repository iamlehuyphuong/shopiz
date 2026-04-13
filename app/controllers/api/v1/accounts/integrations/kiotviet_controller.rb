# API controller for KiotViet integration.
# Provides connect (auth), disconnect, and data retrieval endpoints.
# Unlike Shopify (OAuth redirect), KiotViet uses client_credentials grant
# so connection is a simple POST with client_id, client_secret, retailer.
class Api::V1::Accounts::Integrations::KiotvietController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:auth]

  def auth
    validate_auth_params!

    token_data = fetch_access_token
    return render json: { error: 'Failed to authenticate with KiotViet' }, status: :unprocessable_entity if token_data.nil?

    hook = create_or_update_hook(token_data)
    render json: { status: 'connected', hook_id: hook.id }
  end

  def orders
    customer_id = find_customer_id
    return render json: { invoices: [] } if customer_id.nil?

    invoices = kiotviet_get('invoices', { customerIds: customer_id, pageSize: 20, orderDirection: 'Desc' })
    render json: { invoices: invoices&.dig('data') || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    products = kiotviet_get('products', { pageSize: 50, includeInventory: true, isActive: true })
    render json: { products: products&.dig('data') || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def customers
    customers = kiotviet_get('customers', { pageSize: 20 })
    render json: { customers: customers&.dig('data') || [] }
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
    %i[client_id client_secret retailer].each do |key|
      raise ActionController::ParameterMissing, key if params[key].blank?
    end
  end

  def fetch_access_token
    response = Faraday.post('https://id.kiotviet.vn/connect/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        scopes: 'PublicApi.Access',
        grant_type: 'client_credentials',
        client_id: params[:client_id],
        client_secret: params[:client_secret]
      )
    end
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("KiotViet auth error: #{e.message}")
    nil
  end

  def create_or_update_hook(token_data)
    expires_at = Time.current + token_data['expires_in'].to_i.seconds

    hook = Integrations::Hook.find_or_initialize_by(account: Current.account, app_id: 'kiotviet')
    hook.update!(
      access_token: token_data['access_token'],
      reference_id: params[:retailer],
      settings: {
        'retailer' => params[:retailer],
        'client_id' => params[:client_id],
        'client_secret' => params[:client_secret],
        'token_expires_at' => expires_at.iso8601
      }
    )
    hook
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'kiotviet')
  end

  def find_customer_id
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return nil if contact.blank?

    result = if contact.phone_number.present?
               kiotviet_get('customers', { contactNumber: contact.phone_number, pageSize: 1 })
             elsif contact.name.present?
               kiotviet_get('customers', { name: contact.name, pageSize: 1 })
             end
    result&.dig('data')&.first&.dig('id')
  end

  def kiotviet_get(endpoint, params = {})
    ensure_valid_token

    response = Faraday.get("https://public.kiotapi.com/#{endpoint}") do |req|
      req.headers['Retailer'] = @hook.settings['retailer']
      req.headers['Authorization'] = "Bearer #{@hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    JSON.parse(response.body)
  end

  def ensure_valid_token
    expires_at = @hook.settings&.dig('token_expires_at')
    return if expires_at.present? && Time.zone.parse(expires_at) > Time.current

    refresh_token
  end

  def refresh_token
    token_data = fetch_token_with_credentials
    return if token_data.nil? || token_data['access_token'].blank?

    expires_at = Time.current + token_data['expires_in'].to_i.seconds
    @hook.update!(
      access_token: token_data['access_token'],
      settings: @hook.settings.merge('token_expires_at' => expires_at.iso8601)
    )
  end

  def fetch_token_with_credentials
    response = Faraday.post('https://id.kiotviet.vn/connect/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        scopes: 'PublicApi.Access',
        grant_type: 'client_credentials',
        client_id: @hook.settings['client_id'],
        client_secret: @hook.settings['client_secret']
      )
    end
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("KiotViet token refresh error: #{e.message}")
    nil
  end
end
