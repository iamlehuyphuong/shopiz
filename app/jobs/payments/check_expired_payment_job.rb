module Payments
  class CheckExpiredPaymentJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = ConversationOrder.find_by(id: order_id)
      return if order.blank?

      # If the order is still unpaid after 15 minutes, mark as expired
      return unless order.unpaid?

      Payments::HandlePaymentEventService.new(
        order: order,
        event_type: 'expired'
      ).perform
    end
  end
end
