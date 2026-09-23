# Public tool: Confirm a draft order and push it to the external platform.
class Captain::Tools::PushOrderTool < Captain::Tools::BasePublicTool
  description 'Confirm a draft order and submit it to the integrated external e-commerce platform.'
  param :order_id, type: 'string', desc: 'The ID of the draft order to confirm', required: true

  def active?
    @assistant&.account&.active_ecommerce_platform.present? && @assistant&.account&.ai_allow_create_order
  end

  def perform(tool_context, order_id:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    order = conversation.conversation_orders.find_by(id: order_id)
    return "Order ##{order_id} not found in this conversation" unless order

    return "Order ##{order_id} is not in draft status" unless order.draft?

    if order.external_source.blank? || order.external_source == 'shopiz'
      order.update!(status: :confirmed)
      log_tool_usage('confirm_order', { order_id: order.id, external_source: 'shopiz' })
      return "✅ Local order ##{order.id} has been confirmed successfully."
    end

    user = find_user(conversation)
    result = ConversationOrders::PushService.new(order: order, user: user).perform
    if result[:success]
      log_tool_usage('confirm_order', { order_id: order.id, external_source: order.external_source, success: true })
      "✅ Order ##{order.id} confirmed and successfully pushed to #{order.external_source.capitalize}. External Order ID: #{order.external_order_id}"
    else
      log_tool_usage('confirm_order', { order_id: order.id, external_source: order.external_source, success: false })
      "❌ Failed to push order to #{order.external_source}: #{result[:error]}"
    end
  end

  private

  def find_user(conversation)
    # The current user might be the agent assigned or the assistant itself
    conversation.assignee || conversation.account.users.first
  end
end
