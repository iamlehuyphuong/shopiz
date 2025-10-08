require 'net/http'
require 'json'

class Payos::Client
  attr_reader :client_id, :api_key, :checksum_key, :base_url

  def initialize(client_id: ENV.fetch('PAYOS_CLIENT_ID', nil),
                 api_key: ENV.fetch('PAYOS_API_KEY', nil),
                 checksum_key: ENV.fetch('PAYOS_CHECKSUM_KEY', nil),
                 base_url: default_base_url)
    @client_id = client_id
    @api_key = api_key
    @checksum_key = checksum_key
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
    {
      'x-client-id' => client_id,
      'x-api-key' => api_key,
      'Content-Type' => 'application/json'
    }
  end

  def default_base_url
    'https://api-merchant.payos.vn'
  end
end
