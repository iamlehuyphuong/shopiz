module Payments
  module Providers
    class TingeeProvider < BaseProvider
      def create_checkout(amount:, order_id:, description:, return_url:, cancel_url: nil)
        # For Static QR, we generate the QR code on the fly when the user visits the checkout link.
        { checkout_url: '', form_params: nil }
      end

      def generate_static_qr(bank_bin:, account_number:, amount:, content:)
        payload = {
          bankBin: bank_bin.to_s,
          accountNumber: account_number.to_s,
          amount: amount.to_i,
          content: content.to_s
        }

        # Add merchantId if configured (for master merchant)
        payload[:merchantId] = config['merchant_id'].to_i if config['merchant_id'].present?

        request_body = payload.to_json
        timestamp = Time.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%Y%m%d%H%M%S%L')
        signature_data = "#{timestamp}:#{request_body}"
        signature = OpenSSL::HMAC.hexdigest('SHA512', config['api_key'].to_s, signature_data)

        headers = {
          'Content-Type' => 'application/json',
          'x-client-id' => config['client_id'].to_s,
          'x-request-timestamp' => timestamp,
          'x-signature' => signature
        }

        url = 'https://open-api.tingee.vn/v1/generate-viet-qr'
        response = HTTParty.post(url, headers: headers, body: request_body)

        parsed_response = response.parsed_response
        unless parsed_response && parsed_response['code'] == '00'
          error_message = parsed_response.is_a?(Hash) ? parsed_response['message'] : response.body
          raise StandardError, "Tingee API Error: #{error_message}"
        end

        parsed_response.dig('data', 'qrCodeImage')
      end

      def verify_webhook(payload, headers = {}, raw_body = nil)
        timestamp = headers['x-request-timestamp'] || headers['X-Request-Timestamp']
        provided_signature = headers['x-signature'] || headers['X-Signature']

        return false if timestamp.blank? || provided_signature.blank? || config['api_key'].blank?

        # Tingee Webhook sends POST request with JSON body.
        # Use raw_body (minified JSON string) from request.raw_post if available to ensure accurate signature matching.
        request_body = raw_body || payload.to_json
        signature_data = "#{timestamp}:#{request_body}"
        expected_signature = OpenSSL::HMAC.hexdigest('SHA512', config['api_key'].to_s, signature_data)

        ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
      end

      def extract_webhook_data(payload)
        # Tingee Webhook IPN payload:
        # {
        #   "transactionCode": "12345",
        #   "amount": 100000,
        #   "content": "transaction_id_123",
        #   "type": "credit" or "debit"
        # }
        transaction_id = payload['content'].to_s.strip
        amount = payload['amount'].to_i

        # Only process 'credit' as success. If it's a refund ('debit') or something else, mark as failed.
        status = payload['type'] == 'credit' ? 'success' : 'failed'

        {
          transaction_id: transaction_id,
          amount: amount,
          status: status,
          gateway_transaction_id: payload['transactionCode'].to_s,
          raw_data: payload
        }
      end
    end
  end
end
