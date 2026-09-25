require 'net/http'
require 'json'

class Sepay::EinvoiceClient
  attr_reader :api_url, :api_token, :template_code, :invoice_series

  class Error < StandardError; end

  def initialize
    @api_url = 'https://einvoice-api.sepay.vn/v1'
    @client_id = GlobalConfig.get_value('SEPAY_EINVOICE_CLIENT_ID').presence || ENV.fetch('SEPAY_EINVOICE_CLIENT_ID', nil)
    @client_secret = GlobalConfig.get_value('SEPAY_EINVOICE_CLIENT_SECRET').presence || ENV.fetch('SEPAY_EINVOICE_CLIENT_SECRET', nil)
    @template_code = GlobalConfig.get_value('SEPAY_EINVOICE_TEMPLATE_CODE').presence || ENV.fetch('SEPAY_EINVOICE_TEMPLATE_CODE', nil)
    @invoice_series = GlobalConfig.get_value('SEPAY_EINVOICE_INVOICE_SERIES').presence || ENV.fetch('SEPAY_EINVOICE_INVOICE_SERIES', nil)
    @provider_account_id = GlobalConfig.get_value('SEPAY_EINVOICE_PROVIDER_ACCOUNT_ID').presence || ENV.fetch('SEPAY_EINVOICE_PROVIDER_ACCOUNT_ID',
                                                                                                              nil)

    raise Error, 'Missing client_id for SePay eInvoice' if @client_id.blank?
    raise Error, 'Missing client_secret for SePay eInvoice' if @client_secret.blank?
    raise Error, 'Missing provider_account_id for SePay eInvoice' if @provider_account_id.blank?
  end

  # Create and optionally issue invoice based on is_draft
  def create_invoice(billing_history, account, is_draft: false)
    fetch_token!

    product_name = billing_history.product_name || 'Dịch vụ phần mềm'
    amount = billing_history.price_amount

    buyer_email = account.email
    buyer_tax_code = account.custom_attributes['tax_code'].to_s.strip
    buyer_address = account.custom_attributes['address'].to_s.strip
    buyer_name_raw = account.name.to_s.strip.presence || account.email

    if buyer_tax_code.present?
      buyer_type = 'business'
      buyer_name = buyer_name_raw
    elsif buyer_address.present?
      buyer_type = 'personal'
      buyer_name = buyer_name_raw
    else
      buyer_type = 'personal'
      buyer_name = 'Người mua không cung cấp thông tin'
    end

    payload = {
      template_code: @template_code,
      invoice_series: @invoice_series,
      issued_date: Time.current.strftime('%Y-%m-%d %H:%M:%S'),
      currency: 'VND',
      provider_account_id: @provider_account_id,
      reference_code: billing_history.order_id,
      payment_method: 'CK',
      is_draft: is_draft,
      buyer: {
        type: buyer_type,
        name: buyer_name,
        legal_name: buyer_name,
        tax_code: buyer_tax_code,
        address: buyer_address,
        email: buyer_email
      },
      items: [
        {
          line_number: 1,
          line_type: 1,
          item_code: "PRD-#{billing_history.product_id}",
          item_name: product_name,
          unit: 'Gói',
          quantity: 1,
          unit_price: amount,
          tax_rate: 10 # Default 10% VAT
        }
      ]
    }

    response = request(:post, '/invoices/create', payload)

    unless response[:success]
      Rails.logger.error("[SePay eInvoice] Failed to create invoice: #{response}")
      raise Error, "Create invoice failed: #{response.dig(:error, :message) || response[:message]}"
    end

    response
  end

  # Check creation status (especially for async issue)
  def check_invoice_creation(tracking_code)
    fetch_token!
    request(:get, "/invoices/create/check/#{tracking_code}")
  end

  # Get detailed invoice info (including PDF url)
  def get_invoice(reference_code)
    fetch_token!
    request(:get, "/invoices/#{reference_code}")
  end

  private

  def fetch_token!
    return if @api_token.present?

    uri = URI.parse("#{@api_url}/token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    http_request = Net::HTTP::Post.new(uri.request_uri)
    http_request.basic_auth(@client_id, @client_secret)
    # The API docs mention "không cần request body"
    http_request['Accept'] = 'application/json'

    response = http.request(http_request)
    data = JSON.parse(response.body, symbolize_names: true)

    if response.code.to_i == 200 && data[:access_token].present?
      @api_token = data[:access_token]
    elsif data[:success] && data[:data] && data[:data][:access_token].present?
      @api_token = data.dig(:data, :access_token)
    else
      Rails.logger.error("[SePay eInvoice] Failed to fetch token: #{response.body}")
      raise Error, "Token fetch failed: #{data.dig(:error, :message) || 'Unknown error'}"
    end
  rescue JSON::ParserError
    raise Error, 'Invalid JSON response from SePay token endpoint'
  end

  def request(method, path, body = {})
    uri = URI.parse("#{api_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    http_request = Net::HTTP.const_get(method.to_s.capitalize).new(uri.request_uri, headers)
    http_request.body = body.to_json if body.present? && method != :get

    response = http.request(http_request)
    JSON.parse(response.body, symbolize_names: true)
  rescue JSON::ParserError
    { success: false, message: 'Invalid JSON response from SePay eInvoice' }
  rescue StandardError => e
    { success: false, message: e.message }
  end

  def headers
    {
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
