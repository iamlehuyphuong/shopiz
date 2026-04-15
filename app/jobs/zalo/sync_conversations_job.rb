class Zalo::SyncConversationsJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless channel.is_a?(Channel::ZaloOa)

    Zalo::SyncService.new(channel.inbox).perform
  end
end
