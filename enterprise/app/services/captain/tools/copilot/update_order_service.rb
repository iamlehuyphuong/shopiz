# Copilot tool: Agent updates an existing order via AI and syncs it to the external platform.
class Captain::Tools::Copilot::UpdateOrderService < Captain::Tools::BaseTool
  def self.name
    'update_order'
  end

  description 'Update customer information (name, phone, address, note) of an existing order and sync to external platform.'
  param :conversation_id, type: :integer, desc: 'Conversation display ID', required: true
  param :order_id, type: :integer, desc: 'The ID of the order to update', required: true
  param :customer_name, type: :string, desc: 'New customer name', required: false
  param :customer_phone, type: :string, desc: 'New customer phone', required: false
  param :customer_address, type: :string, desc: 'New customer address', required: false
  param :customer_note, type: :string, desc: 'New order note', required: false

  def execute(conversation_id:, order_id:, customer_name: nil, customer_phone: nil, customer_address: nil, customer_note: nil)
    conversation = find_conversation(conversation_id)
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

    return "✅ Local order ##{order.id} updated successfully." if order.external_source.blank? || order.external_source == 'shopiz'

    # If it's still a draft, we don't need to sync to external yet (will push later)
    return "✅ Draft order ##{order.id} updated locally." if order.draft?

    # Sync update to platform
    result = ConversationOrders::UpdateService.new(order: order, user: @user).perform
    if result[:success]
      "✅ Order ##{order.id} updated and successfully synced to #{order.external_source.capitalize}."
    else
      "⚠️ Order updated locally, but failed to sync to #{order.external_source}: #{result[:error]}"
    end
  end

  def active?
    @user.present?
  end

  private

  def find_conversation(display_id)
    Conversation.find_by(account_id: @assistant.account_id, display_id: display_id)
  end
end
