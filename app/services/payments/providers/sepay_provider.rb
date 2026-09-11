module Payments
  module Providers
    class SepayProvider < BaseProvider
      def create_checkout(amount:, order_id:, description:, return_url:, cancel_url: nil)
        client = Sepay::Client.new(merchant_id: config['company_code'], secret_key: config['secret_key'])

        client.create_checkout(
          amount: amount,
          order_id: order_id,
          description: description,
          return_url: return_url,
          cancel_url: cancel_url,
          error_url: return_url
        )
      end

      def verify_webhook(_payload, headers = {})
        provided_key = headers['Authorization'].to_s.gsub(/Bearer\s+|Apikey\s+/i, '').strip
        provided_key = headers['X-Secret-Key'].to_s.strip if provided_key.blank?
        return false if provided_key.blank?
        return false if config['secret_key'].blank?

        ActiveSupport::SecurityUtils.secure_compare(provided_key, config['secret_key'])
      end

      def extract_webhook_data(payload)
        # Payment Gateway IPN puts order info inside 'order' object
        transaction_id = payload.dig('order', 'order_invoice_number') || payload['content']
        amount = payload.dig('order', 'order_amount') || payload['transferAmount']

        # Payment Gateway has 'transaction' ref
        gateway_transaction_id = payload.dig('transaction',
                                             'transaction_id').to_s.presence || payload.dig('transaction', 'id').to_s.presence || payload['id'].to_s

        {
          transaction_id: transaction_id.to_s.strip,
          amount: amount.to_i,
          status: 'success', # SePay IPNs are typically only sent on successful transfers
          gateway_transaction_id: gateway_transaction_id,
          raw_data: payload
        }
      end
    end
  end
end
