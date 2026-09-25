class Webhooks::TiktokShopMessagesJob < MutexApplicationJob
  queue_as :default

  SUPPORTED_TYPE = 14

  def perform(data)
    return if data['type'] != SUPPORTED_TYPE

    channel_tiktok_shop = Channel::TiktokShop.find_by(shop_id: data['shop_id'])
    return unless channel_tiktok_shop

    TiktokShop::IncomingMessageService.new(inbox: channel_tiktok_shop.inbox, params: data.with_indifferent_access).perform
  end

  def lock_key(data)
    "tiktok_shop_messages_#{data['conversation_id']}"
  end
end
