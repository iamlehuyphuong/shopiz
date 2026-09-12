class Captain::Tools::CheckPaymentStatusTool < Captain::Tools::BasePublicTool
  description 'Check the current payment status of the active order for the conversation.'

  def perform(tool_context)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    order = conversation.conversation_orders.ordered.first
    return 'No active order found for this conversation.' unless order

    log_tool_usage('check_payment_status', { conversation_id: conversation.id, order_id: order.id, status: order.payment_status })

    case order.payment_status
    when 'paid'
      "The order ##{order.id} has been paid successfully."
    when 'expired'
      "The payment link for order ##{order.id} has expired."
    when 'failed'
      "The payment for order ##{order.id} has failed."
    else
      "The order ##{order.id} is currently unpaid."
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    "Failed to check payment status: #{e.message}"
  end
end
