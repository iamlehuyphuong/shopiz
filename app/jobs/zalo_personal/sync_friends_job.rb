class ZaloPersonal::SyncFriendsJob < ApplicationJob
  queue_as :low

  def perform(inbox_id)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    ZaloPersonal::SyncFriendsService.new(inbox).perform
  end
end
