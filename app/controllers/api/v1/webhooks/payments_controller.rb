module Api
  module V1
    module Webhooks
      class PaymentsController < ActionController::API
        def create
          provider_name = params[:provider]
          account_id = params[:account_id]

          account = Account.find_by(id: account_id)
          return head :not_found unless account

          provider_class = Payments::ProviderRegistry.provider_for(provider_name)
          return head :not_found unless provider_class

          config = account.settings['sales_payment_config']&.dig(provider_name) || {}
          provider = provider_class.new(config)

          begin
            payload_data = request.request_parameters

            unless provider.verify_webhook(payload_data, request.headers)
              Rails.logger.warn("Payments Webhook invalid signature for #{provider_name} - account #{account.id}")
              return render json: { error: 'Invalid signature' }, status: :unauthorized
            end

            payload = provider.extract_webhook_data(payload_data)

            order = account.conversation_orders.find_by(payment_transaction_id: payload[:transaction_id])

            if order
              Payments::HandlePaymentEventService.new(
                order: order,
                event_type: payload[:status]
              ).perform
            end

            render json: { success: true }, status: :ok
          rescue StandardError => e
            Rails.logger.error("Payments Webhook failed: #{e.message}")
            render json: { error: e.message }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
