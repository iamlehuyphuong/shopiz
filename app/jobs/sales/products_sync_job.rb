class Sales::ProductsSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id, platform)
    account = Account.find_by(id: account_id)
    return unless account

    Sales::ProductsSyncService.new(account: account, platform: platform).perform
  end
end
