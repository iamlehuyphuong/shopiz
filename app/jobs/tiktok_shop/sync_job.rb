class TiktokShop::SyncJob < ApplicationJob
  queue_as :default

  def perform(channel_id)
    channel = Channel::TiktokShop.find_by(id: channel_id)
    return unless channel

    TiktokShop::SyncService.new(channel).perform
  end
end
