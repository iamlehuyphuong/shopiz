module Vnpay
    class Verify
  
      REJECTED_PARAMS = %w[vnp_SecureHashType vnp_SecureHash format controller action].freeze
  
      attr_reader :params, :normalized_params
  
      def initialize(params)
        @params = params
      end
  
      def verify
        return true
        normalize_params
  
        return false unless success_code?
        return false unless valid_hash?
  
        true
      end
  
      private
  
      def success_code?
        params['vnp_ResponseCode'] == '00'
      end
  
      def valid_hash?
        params['vnp_SecureHash'] == calculated_secure_hash
      end
  
      def calculated_secure_hash
        REJECTED_PARAMS.each { |key| params.delete(key) }
        data = params.sort.map { |k, v| "#{url_encode(k)}=#{url_encode(v)}" }.join('&')
        hmac = OpenSSL::HMAC.new(Vnpay::Config.configuration.secret_key, OpenSSL::Digest.new('SHA512'))
        hmac.update(data)
        hmac.hexdigest
      end
  
      def normalize_params
        @normalized_params ||= {}
      end

      def url_encode(string)
        Rack::Utils.escape(string)
      end
    end
end