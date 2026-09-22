class Payments::GeneratePaymentJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = ConversationOrder.find_by(id: order_id)
    return if order.blank? || order.conversation.blank?

    # We only generate payment if method is supported and it's unpaid
    provider_name = order.payment_method
    return unless %w[sepay payos tingee].include?(provider_name)
    return unless order.unpaid?

    result = Payments::LinkGeneratorService.new(
      order: order,
      provider_name: provider_name
    ).perform

    return unless result[:success]

    # Send Payment Link to conversation
    send_payment_link_to_conversation(order, result[:checkout_url])
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
