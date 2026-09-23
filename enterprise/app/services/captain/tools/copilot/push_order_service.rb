# Copilot tool: Agent confirms a draft order via AI and pushes it to the external platform.
class Captain::Tools::Copilot::PushOrderService < Captain::Tools::BaseTool
  def self.name
    'push_order'
  end

  description 'Confirm a draft order and submit it to the integrated external platform (or finalize it if local).'
  param :conversation_id, type: :integer, desc: 'Conversation display ID', required: true
  param :order_id, type: :integer, desc: 'The ID of the draft order to confirm', required: true

  def execute(conversation_id:, order_id:)
    conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless conversation

    order = conversation.conversation_orders.find_by(id: order_id)
    return "Order ##{order_id} not found in this conversation" unless order

    return "Order ##{order_id} is not in draft status" unless order.draft?

    # If it's a shopiz local order (no external source), just update status
    if order.external_source.blank? || order.external_source == 'shopiz'
      order.update!(status: :confirmed)
      return "✅ Local order ##{order.id} has been confirmed successfully."
    end

    # Otherwise push to platform
    result = ConversationOrders::PushService.new(order: order, user: @user).perform
    if result[:success]
      "✅ Order ##{order.id} confirmed and successfully pushed to #{order.external_source.capitalize}. External Order ID: #{order.external_order_id}"
    else
      "❌ Failed to push order to #{order.external_source}: #{result[:error]}"
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
