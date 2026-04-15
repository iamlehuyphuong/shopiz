require 'net/http'
require 'json'

class Payos::Client
  attr_reader :client_id, :api_key, :checksum_key, :partner_id, :base_url

  def initialize(client_id: GlobalConfig.get_value('PAYOS_CLIENT_ID').presence || ENV.fetch('PAYOS_CLIENT_ID', nil),
                 api_key: GlobalConfig.get_value('PAYOS_API_KEY').presence || ENV.fetch('PAYOS_API_KEY', nil),
                 checksum_key: GlobalConfig.get_value('PAYOS_CHECKSUM_KEY').presence || ENV.fetch('PAYOS_CHECKSUM_KEY', nil),
                 partner_id: GlobalConfig.get_value('PAYOS_PARTNER_ID').presence || ENV.fetch('PAYOS_PARTNER_ID', nil),
                 base_url: default_base_url)
    @client_id = client_id
    @api_key = api_key
    @checksum_key = checksum_key
    @partner_id = partner_id
    @base_url = base_url
  end

  def create_payment_link(payload)
    payload[:signature] = Payos::Signature.generate(payload, checksum_key)

    request(:post, '/v2/payment-requests', payload)
  end

  def verify_signature?(payload)
    Payos::Signature.verify(payload, checksum_key)
  end

  private

  def request(_method, path, body = {})
    uri = URI.join(base_url, path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri, headers)
    request.body = body.to_json

    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  end

  def headers
    h = {
      'x-client-id' => client_id,
      'x-api-key' => api_key,
      'Content-Type' => 'application/json'
    }
    h['x-partner-code'] = partner_id if partner_id.present?
    h
  end

  def default_base_url
    'https://api-merchant.payos.vn'
  end
end

