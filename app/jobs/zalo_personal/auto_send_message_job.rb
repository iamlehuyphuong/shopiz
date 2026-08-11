class ZaloPersonal::AutoSendMessageJob < ApplicationJob
  queue_as :default

  def perform(inbox_id, phone_number)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox&.zalo_personal?

    channel = inbox.channel

    user_info = load_user_info(channel, phone_number)
    return unless user_info

    uid = user_info['uid']
    is_fr = user_info['isFr']

    unless is_fr
      request_msg = channel.default_friend_request_message
      send_friend_request(channel, uid, request_msg) if request_msg.present?
    end

    greeting_msg = channel.default_greeting_message
    channel.send_text_message(uid, greeting_msg) if greeting_msg.present?
  end

  private

  def load_user_info(channel, phone_number)
    body = { phone: phone_number, ownId: channel.oa_id }
    res = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/findUser",
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
    res['success'] ? res['data'] : nil
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal::AutoSendMessageJob load_user_info failed: #{e.message}"
    nil
  end

  def send_friend_request(channel, uid, message)
    body = { userId: uid, ownId: channel.oa_id, message: message }
    HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendFriendRequest",
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal::AutoSendMessageJob send_friend_request failed: #{e.message}"
  end
end
