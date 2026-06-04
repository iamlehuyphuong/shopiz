# Background job to send order status update notifications.
# Decoupled from the ConversationOrder model callback for safer error handling and retries.
class ConversationOrders::SendStatusUpdateJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = ConversationOrder.find_by(id: order_id)
    return if order.blank? || order.conversation.blank?

    ConversationOrders::SendUtilityMessageService.new(
      order: order,
      conversation: order.conversation
    ).perform
  rescue StandardError => e
    Rails.logger.error("SendStatusUpdateJob failed for order #{order_id}: #{e.message}")
    raise # Re-raise for Sidekiq retry
  end
end
