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

          if request.get?
            return render json: { code: '00', message: 'Success' }, status: :ok if provider_name == 'tingee'

            return render json: { success: true }, status: :ok

          end

          config = account.sales_payment_config&.dig(provider_name) || {}
          provider = provider_class.new(config)

          begin
            payload_data = request.request_parameters

            unless provider.verify_webhook(payload_data, request.headers, request.raw_post)
              Rails.logger.warn("Payments Webhook invalid signature for #{provider_name} - account #{account.id}")
              return render json: { error: 'Invalid signature' }, status: :unauthorized
            end

            payload = provider.extract_webhook_data(payload_data)

            order = account.conversation_orders.find_by(payment_transaction_id: payload[:transaction_id])

            if order.blank? && payload[:amount].to_i > 0
              # Fallback fuzzy matching for cases where content is missing or modified
              order = account.conversation_orders
                             .where(payment_method: provider_name, payment_status: 'unpaid')
                             .where(total_amount: payload[:amount].to_i)
                             .where('created_at >= ?', 3.hours.ago)
                             .order(created_at: :desc)
                             .first

              if order
                Rails.logger.warn("Payments Webhook: Fuzzy matched order #{order.id} for amount #{payload[:amount]} (content: #{payload[:transaction_id]})")
              end
            end

            if order
              Payments::HandlePaymentEventService.new(
                order: order,
                event_type: payload[:status]
              ).perform
            end

            if provider_name == 'tingee'
              render json: { code: '00', message: 'Success' }, status: :ok
            else
              render json: { success: true }, status: :ok
            end
          rescue StandardError => e
            Rails.logger.error("Payments Webhook failed: #{e.message}")
            render json: { error: e.message }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
