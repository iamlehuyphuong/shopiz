class Webhooks::TiktokMessagesJob < ApplicationJob
  queue_as :default

  SUPPORTED_TYPE = 14

  def perform(data)
    return if data["type"] != SUPPORTED_TYPE

    channel_tiktok = Channel::Tiktok.find_by(shop_id: data["shop_id"])
    return unless channel_tiktok

    Tiktok::IncomingMessageService.new(inbox: channel_tiktok.inbox, params: data.with_indifferent_access).perform
  end
end
