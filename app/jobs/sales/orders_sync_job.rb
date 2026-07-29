class Sales::OrdersSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, platform, timeframe = '1_month')
    account = Account.find(account_id)

    # Sync customers first
    Contacts::PullHistoricalCustomersService.new(
      account.id,
      platform,
      timeframe
    ).perform

    # Then sync orders
    ConversationOrders::PullHistoricalOrdersService.new(
      account.id,
      platform,
      timeframe
    ).perform
  rescue StandardError => e
    Rails.logger.error("Sales::OrdersSyncJob failed for account #{account_id}, platform #{platform}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
