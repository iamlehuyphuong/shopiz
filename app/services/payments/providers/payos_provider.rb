module Payments
  module Providers
    class PayosProvider < BaseProvider
      def create_checkout(amount:, order_id:, description:, return_url:, cancel_url: nil)
        client = Payos::Client.new(
          client_id: config['client_id'],
          api_key: config['api_key'],
          checksum_key: config['checksum_key'],
          partner_id: config['partner_id']
        )
        service = Payos::PaymentService.new(client: client)

        result = service.create_order(
          amount: amount,
          order_code: order_id.to_i, # PayOS orderCode must be a number
          return_url: return_url,
          cancel_url: cancel_url || return_url,
          description: description
        )

        {
          checkout_url: result.dig(:data, :checkoutUrl),
          form_params: nil # PayOS does not need form params
        }
      end

      def verify_webhook(payload, _headers = {})
        client = Payos::Client.new(
          client_id: config['client_id'],
          api_key: config['api_key'],
          checksum_key: config['checksum_key'],
          partner_id: config['partner_id']
        )

        client.verify_signature?(payload)
      end

      def extract_webhook_data(payload)
        data = payload['data'] || payload[:data] || payload

        status = payload['code'] == '00' || payload[:code] == '00' ? 'success' : 'failed'

        {
          transaction_id: data['orderCode'].to_s,
          amount: data['amount'].to_i,
          status: status,
          gateway_transaction_id: data['reference'],
          raw_data: payload
        }
      end
    end
  end
end
