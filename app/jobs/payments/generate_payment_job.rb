module Payments
  class GeneratePaymentJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = ConversationOrder.find_by(id: order_id)
      return if order.blank? || order.conversation.blank?

      # We only generate payment if method is supported and it's unpaid
      provider_name = order.payment_method
      return unless %w[sepay payos tingee].include?(provider_name)
      return unless order.unpaid?

      provider_class = Payments::ProviderRegistry.provider_for(provider_name)
      return unless provider_class

      config = order.account.settings['sales_payment_config']&.dig(provider_name) || {}
      provider = provider_class.new(config)

      transaction_id = "ORDER#{order.id}T#{Time.current.to_i}"
      amount = order.total_amount.to_i
      description = "Thanh toan don hang #{order.id}"
      return_url = ENV.fetch('FRONTEND_URL', 'https://shopiz.pro')

      result = provider.create_checkout(
        amount: amount,
        order_id: transaction_id,
        description: description,
        return_url: return_url
      )

      # For PayOS, the API returns a GET checkoutUrl that the user can visit.
      # For SePay Payment Gateway, the API returns form_params that must be POSTed.
      # So we route SePay through our internal redirect controller.
      checkout_link = if provider_name == 'sepay'
                        "#{return_url}/api/v1/payments/sepay_checkout/#{transaction_id}"
                      else
                        result[:checkout_url]
                      end

      return if checkout_link.blank?

      # Save tracking info to order
      order.update!(
        payment_provider: provider_name,
        payment_transaction_id: transaction_id,
        payment_qr_url: checkout_link # We reuse this field for DB compatibility
      )

      # Send Payment Link to conversation
      send_payment_link_to_conversation(order, checkout_link)

      # Enqueue expiration check (15 minutes for SePay/PayOS)
      Payments::CheckExpiredPaymentJob.set(wait: 15.minutes).perform_later(order.id)
    rescue StandardError => e
      Rails.logger.error("GeneratePaymentJob failed for order #{order_id}: #{e.message}")
    end

    private

    def send_payment_link_to_conversation(order, checkout_link)
      conversation = order.conversation

      message_content = I18n.t(
        'conversation_orders.payment.instruction',
        default: "Vui lòng truy cập đường dẫn sau để thanh toán đơn hàng ##{order.id}:"
      ) + "\n#{checkout_link}"

      # Use MessageBuilder to send the text link
      message_params = {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: 'outgoing',
        content: message_content,
        private: false
      }

      builder = Messages::MessageBuilder.new(nil, conversation, message_params)
      builder.perform
    end
  end
end
