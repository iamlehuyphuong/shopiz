# Public tool: Update an existing order and sync it to the external platform.
class Captain::Tools::UpdateOrderTool < Captain::Tools::BasePublicTool
  description 'Update customer information (name, phone, address, note) of an existing order and sync to external platform.'
  param :order_id, type: 'string', desc: 'The ID of the order to update', required: true
  param :customer_name, type: 'string', desc: 'New customer name', required: false
  param :customer_phone, type: 'string', desc: 'New customer phone', required: false
  param :customer_address, type: 'string', desc: 'New customer address', required: false
  param :customer_note, type: 'string', desc: 'New order note', required: false

  def active?
    @assistant&.account&.active_ecommerce_platform.present? && @assistant&.account&.ai_allow_create_order
  end

  def perform(tool_context, order_id:, customer_name: nil, customer_phone: nil, customer_address: nil, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    order = conversation.conversation_orders.find_by(id: order_id)
    return "Order ##{order_id} not found in this conversation" unless order

    updates = {}
    updates[:customer_name] = customer_name if customer_name.present?
    updates[:customer_phone] = customer_phone if customer_phone.present?
    updates[:customer_address] = customer_address if customer_address.present?
    updates[:customer_note] = customer_note if customer_note.present?

    return 'No update fields provided' if updates.empty?

    order.update!(updates)
    log_tool_usage('update_order', { order_id: order.id, updates: updates.keys })

    return "✅ Local order ##{order.id} updated successfully." if order.external_source.blank? || order.external_source == 'shopiz'

    return "✅ Draft order ##{order.id} updated locally." if order.draft?

    user = find_user(tool_context.state)
    result = ConversationOrders::UpdateService.new(order: order, user: user).perform
    if result[:success]
      "✅ Order ##{order.id} updated and successfully synced to #{order.external_source.capitalize}."
    else
      "⚠️ Order updated locally, but failed to sync to #{order.external_source}: #{result[:error]}"
    end
  end

  private

  def find_user(state)
    state.conversation.assignee || state.conversation.account.users.first
  end
end
