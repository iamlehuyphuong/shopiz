module Payments
  module Providers
    class TingeeProvider < BaseProvider
      def create_checkout(amount:, order_id:, description:, return_url:, cancel_url: nil)
        payload = {
          requestId: SecureRandom.uuid,
          orderId: order_id.to_s,
          amount: amount.to_i,
          description: description,
          returnUrl: return_url
        }

        # Add merchantId if configured (for master merchant)
        payload[:merchantId] = config['merchant_id'].to_i if config['merchant_id'].present?

        # Minified JSON string
        request_body = payload.to_json

        # Tingee requires UTC+7 for timestamp. %L is milliseconds.
        timestamp = Time.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%Y%m%d%H%M%S%L')
        signature_data = "#{timestamp}:#{request_body}"
        signature = OpenSSL::HMAC.hexdigest('SHA512', config['checksum_key'].to_s, signature_data)

        headers = {
          'Content-Type' => 'application/json',
          'x-client-id' => config['client_id'].to_s,
          'x-request-timestamp' => timestamp,
          'x-signature' => signature
        }

        url = 'https://open-api.tingee.vn/v1/payment-gateway/create-link'
        response = HTTParty.post(url, headers: headers, body: request_body)

        parsed_response = response.parsed_response
        unless parsed_response && parsed_response['code'] == '00'
          error_message = parsed_response.is_a?(Hash) ? parsed_response['message'] : response.body
          raise StandardError, "Tingee API Error: #{error_message}"
        end

        {
          checkout_url: parsed_response['data'],
          form_params: nil
        }
      end

      def verify_webhook(payload, headers = {})
        timestamp = headers['x-request-timestamp'] || headers['X-Request-Timestamp']
        provided_signature = headers['x-signature'] || headers['X-Signature']

        return false if timestamp.blank? || provided_signature.blank? || config['checksum_key'].blank?

        # Tingee Webhook sends POST request with JSON body.
        # Re-stringify the payload to match the raw body.
        request_body = payload.to_json
        signature_data = "#{timestamp}:#{request_body}"
        expected_signature = OpenSSL::HMAC.hexdigest('SHA512', config['checksum_key'].to_s, signature_data)

        ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
      end

      def extract_webhook_data(payload)
        transaction_id = payload['orderId'] || payload['transactionId'] || payload['id']
        amount = payload['amount'] || payload['transferAmount']

        # Tingee status could be true/false, 'SUCCESS', '00', etc. Let's be flexible.
        status = payload['status'] == 'success' || payload['status'] == 'SUCCESS' || payload['code'] == '00' ? 'success' : 'failed'

        {
          transaction_id: transaction_id.to_s,
          amount: amount.to_i,
          status: status,
          gateway_transaction_id: payload['transactionId'].to_s,
          raw_data: payload
        }
      end
    end
  end
end
