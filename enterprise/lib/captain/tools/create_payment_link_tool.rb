class Captain::Tools::CreatePaymentLinkTool < Captain::Tools::BasePublicTool
  description 'Create a payment link for the customer to pay for their order.'
  param :order_id, type: 'string', desc: 'The ID of the order. If not provided, uses the latest unpaid order.', required: false
  param :payment_method, type: 'string', desc: 'The payment method to use (e.g. tingee, sepay, payos)', required: false

  def active?
    @assistant&.account&.active_ecommerce_platform.present? && @assistant&.account&.ai_allow_create_order
  end

  def perform(tool_context, payment_method: 'tingee', order_id: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    order = if order_id.present?
              conversation.conversation_orders.find_by(id: order_id)
            else
              conversation.conversation_orders.ordered.first
            end

    return 'No active order found for this conversation. Please create an order first.' unless order

    result = Payments::LinkGeneratorService.new(
      order: order,
      provider_name: payment_method
    ).perform

    return result[:error] unless result[:success]

    log_tool_usage('create_payment_link', { conversation_id: conversation.id, order_id: order.id, provider: result[:provider_name] })

    "Payment link generated successfully: #{result[:checkout_url]}. Please send this link to the customer and ask them to pay."
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    "Failed to create payment link: #{e.message}"
  end
end
