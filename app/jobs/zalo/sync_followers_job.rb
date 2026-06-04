# Background job to sync all Zalo OA followers to Shopiz contacts
# Triggered when a new Zalo OA channel is created or manually via admin
class Zalo::SyncFollowersJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless channel.is_a?(Channel::ZaloOa)

    Zalo::FollowerSyncService.new(channel.inbox).perform
  end
end
