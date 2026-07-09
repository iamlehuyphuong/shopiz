# API controller for Nhanh.vn integration.
# Provides connect (auth), disconnect, and data retrieval endpoints.
# Nhanh.vn uses POST form-data with appId + accessToken + businessId authentication
# against https://open.nhanh.vn API v2.
class Api::V1::Accounts::Integrations::NhanhvnController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:auth]

  NHANHVN_API_BASE = 'https://open.nhanh.vn'.freeze

  def auth
    validate_auth_params!

    test_result = test_connection
    return render json: { error: 'Failed to authenticate with Nhanh.vn' }, status: :unprocessable_entity if test_result.nil?

    hook = create_or_update_hook
    render json: { status: 'connected', hook_id: hook.id }
  end

  def orders
    data = { icpp: 20 }
    if params[:contact_id].present?
      filters = find_contact_filters
      return render json: { orders: [] } if filters.blank?

      data.merge!(filters)
    end

    result = nhanhvn_post('/api/order/index', data)
    orders_hash = result&.dig('data', 'orders')
    render json: { orders: orders_hash.is_a?(Hash) ? orders_hash.values : [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    data = { icpp: 50 }
    data[:name] = params[:query] if params[:query].present?

    result = nhanhvn_post('/api/product/search', data)
    products_hash = result&.dig('data', 'products')
    render json: { products: products_hash.is_a?(Hash) ? products_hash.values : [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def customers
    data = { icpp: 20 }
    data[:mobile] = params[:mobile] if params[:mobile].present?

    result = nhanhvn_post('/api/customer/search', data)
    customers_data = result&.dig('data', 'customers')
    render json: { customers: customers_data || [] }
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
    %i[app_id access_token business_id].each do |key|
      raise ActionController::ParameterMissing, key if params[key].blank?
    end
  end

  def test_connection
    result = nhanhvn_post_with_credentials('/api/product/search', { icpp: 1 })
    return nil unless result&.dig('code') == 1

    result
  rescue StandardError => e
    Rails.logger.error("Nhanh.vn auth error: #{e.message}")
    nil
  end

  def create_or_update_hook
    hook = Integrations::Hook.find_or_initialize_by(account: Current.account, app_id: 'nhanhvn')
    hook.update!(
      access_token: params[:access_token],
      reference_id: params[:business_id],
      settings: {
        'app_id' => params[:app_id],
        'business_id' => params[:business_id],
        'access_token' => params[:access_token]
      }
    )
    hook
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'nhanhvn')
  end

  def find_contact_filters
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return nil if contact.blank?

    filters = {}
    filters[:customerMobile] = contact.phone_number if contact.phone_number.present?
    filters[:customerEmail] = contact.email if contact.email.present?
    filters.presence
  end

  def nhanhvn_post(endpoint, data = {})
    response = Faraday.post("#{NHANHVN_API_BASE}#{endpoint}") do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        version: '2.0',
        appId: @hook.settings['app_id'],
        businessId: @hook.settings['business_id'],
        accessToken: @hook.access_token,
        data: data.to_json
      )
    end
    parsed = JSON.parse(response.body)
    raise "Nhanh.vn API error: #{parsed['messages']}" unless parsed['code'] == 1

    parsed
  end

  def nhanhvn_post_with_credentials(endpoint, data = {})
    response = Faraday.post("#{NHANHVN_API_BASE}#{endpoint}") do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        version: '2.0',
        appId: params[:app_id],
        businessId: params[:business_id],
        accessToken: params[:access_token],
        data: data.to_json
      )
    end
    JSON.parse(response.body)
  end
end
