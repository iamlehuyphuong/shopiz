module Payments
  module Providers
    class BaseProvider
      attr_reader :config

      def initialize(config)
        @config = config
      end

      # Should return { checkout_url: "...", form_params: {...} }
      def create_checkout(amount:, order_id:, description:, return_url:, cancel_url: nil)
        raise NotImplementedError
      end

      # Should return boolean indicating if webhook signature is valid
      def verify_webhook(payload, headers = {})
        raise NotImplementedError
      end

      # Should return { transaction_id: '...', amount: 1000, status: 'success', raw_data: {} }
      def extract_webhook_data(payload)
        raise NotImplementedError
      end
    end
  end
end
