# Background job that syncs a ConversationOrder when an external platform webhook fires.
# Finds the matching order by external_order_id + external_source, then delegates to SyncService.
class ConversationOrders::WebhookSyncJob < ApplicationJob
  queue_as :default

  def perform(platform:, external_order_id:, account_id: nil)
    orders = find_orders(platform, external_order_id, account_id)
    return if orders.blank?

    orders.each do |order|
      result = ConversationOrders::SyncService.new(order: order).perform
      if result[:success]
        Rails.logger.info("WebhookSync: Order ##{order.id} synced from #{platform} (#{external_order_id})")
      else
        Rails.logger.warn("WebhookSync: Failed to sync order ##{order.id}: #{result[:error]}")
      end
    end
  end

  private

  def find_orders(platform, external_order_id, account_id)
    scope = ConversationOrder.where(external_source: platform, external_order_id: external_order_id.to_s)
    scope = scope.where(account_id: account_id) if account_id.present?
    scope.where.not(status: [:delivered, :cancelled])
  end
end
