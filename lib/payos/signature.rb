require 'openssl'
require 'json'
require 'rack/utils'

module Payos
  module Signature
    module_function

    def flatten_hash(obj, prefix = nil)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), acc|
          key = prefix ? "#{prefix}[#{k}]" : k.to_s
          acc.merge!(flatten_hash(v, key))
        end
      when Array
        arr = obj.map do |item|
          if item.is_a?(Hash)
            flatten_hash(item)
          else
            item.to_s
          end
        end
        { prefix => JSON.generate(arr, ascii_only: false).gsub('nil', 'null') }
      when NilClass
        { prefix => "" }
      else
        { prefix => obj.to_s }
      end
    end

    def generate(payload, checksum_key)
      data = payload.reject { |k,_| k.to_s == 'signature' }
      flat = flatten_hash(data)
      sorted = flat.sort_by { |k,_| k }.map { |k,v| "#{k}=#{v}" }.join("&")
      OpenSSL::HMAC.hexdigest('SHA256', checksum_key.to_s, sorted)
    end

    def verify(payload, checksum_key)
      return false unless payload['signature']

      data_payload = payload['data'] || {}
      expected = generate(data_payload, checksum_key)
      Rack::Utils.secure_compare(expected, payload['signature'])
    end
  end
end
