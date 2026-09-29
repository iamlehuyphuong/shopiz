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

    attachments = []
    
    qr_blob = generate_qr_blob(order)
    attachments << qr_blob if qr_blob

    # Use MessageBuilder to send the text link + qr image
    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: 'outgoing',
      content: message_content,
      attachments: attachments,
      private: false
    }

    builder = Messages::MessageBuilder.new(nil, conversation, message_params)
    builder.perform
  end

  def generate_qr_blob(order)
    provider_name = order.payment_method
    config = order.account.sales_payment_config&.dig(provider_name) || {}

    return nil unless provider_name == 'tingee'

    provider = Payments::Providers::TingeeProvider.new(config)
    base64_data = provider.generate_static_qr(
      bank_bin: config['bank_bin'],
      account_number: config['account_number'],
      amount: order.total_amount.to_i,
      content: order.payment_transaction_id
    )

    if base64_data.start_with?('data:image')
      base64_data = base64_data.split(',').last
    end

    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(Base64.decode64(base64_data)),
      filename: "qr_#{order.payment_transaction_id}.png",
      content_type: 'image/png'
    )
  rescue StandardError => e
    Rails.logger.error("Failed to generate QR blob for order #{order.id}: #{e.message}")
    nil
  end
end
