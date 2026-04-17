require 'openssl'
require 'rack/utils'

module Payos
  module Signature
    module_function

    # Fields required for signing a payment creation request (per PayOS API docs)
    CREATE_SIGNING_FIELDS = %w[amount cancelUrl description orderCode returnUrl].freeze

    # Generate signature for payment creation payload
    # PayOS requires: sort fields alphabetically, join as key=value&key=value, HMAC-SHA256
    def generate(payload, checksum_key)
      data = payload.transform_keys(&:to_s)
      sorted_str = CREATE_SIGNING_FIELDS.sort.map { |k| "#{k}=#{data[k]}" }.join('&')
      OpenSSL::HMAC.hexdigest('SHA256', checksum_key.to_s, sorted_str)
    end

    # Verify webhook signature from PayOS
    # The signature is computed from all fields in the 'data' object, sorted alphabetically
    def verify(payload, checksum_key)
      signature = payload['signature']
      return false if signature.blank?

      data_payload = payload['data']
      return false if data_payload.blank?

      data_str = data_payload.transform_keys(&:to_s)
                             .sort_by { |k, _| k }
                             .map { |k, v| "#{k}=#{v}" }
                             .join('&')
      expected = OpenSSL::HMAC.hexdigest('SHA256', checksum_key.to_s, data_str)
      Rack::Utils.secure_compare(expected, signature)
    end
  end
end
