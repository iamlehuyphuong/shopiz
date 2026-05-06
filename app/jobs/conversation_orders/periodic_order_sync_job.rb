# Periodic background job that syncs ConversationOrders with their external platforms.
# Runs every 30 minutes via sidekiq-cron. Only syncs orders that:
# - Have been pushed (external_order_id present)
# - Are not in terminal status (delivered/cancelled)
# - Haven't been synced in the last 30 minutes
class ConversationOrders::PeriodicOrderSyncJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 50
  SYNC_INTERVAL = 30.minutes

  def perform
    orders_to_sync.find_each(batch_size: BATCH_SIZE) do |order|
      sync_order(order)
    rescue StandardError => e
      Rails.logger.error("PeriodicSync: Failed for order ##{order.id}: #{e.message}")
    end
  end

  private

  def orders_to_sync
    ConversationOrder
      .where.not(external_order_id: [nil, ''])
      .where.not(external_source: [nil, ''])
      .where.not(status: [:delivered, :cancelled])
      .where(last_synced_at: [nil, ..SYNC_INTERVAL.ago])
  end

  def sync_order(order)
    result = ConversationOrders::SyncService.new(order: order).perform
    order.update_column(:last_synced_at, Time.current) if result[:success]
  end
end
