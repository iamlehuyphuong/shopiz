class Contacts::ContactsSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, platform, timeframe = '1_month')
    account = Account.find(account_id)

    Contacts::PullHistoricalCustomersService.new(
      account.id,
      platform,
      timeframe
    ).perform
  rescue StandardError => e
    Rails.logger.error("Contacts::ContactsSyncJob failed for account #{account_id}, platform #{platform}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
