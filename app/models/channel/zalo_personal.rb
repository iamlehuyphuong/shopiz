# == Schema Information
#
# Table name: channel_zalo_personal
#
#  id              :bigint           not null, primary key
#  oa_access_token :string           not null
#  refresh_token   :string           not null
#  expires_in      :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  oa_id           :string           not null
#
# Indexes
#
#  index_channel_zalo_personal_on_oa_id  (oa_id) UNIQUE
#

class Channel::ZaloPersonal < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_zalo_personal'
  store_accessor :provider_config, :default_friend_request_message, :default_greeting_message

  after_create :setup_webhooks
  after_destroy :teardown_webhooks

  EDITABLE_ATTRS = [:oa_access_token, :refresh_token, :expires_in, :default_friend_request_message, :default_greeting_message,
                    { provider_config: {} }].freeze

  validates :oa_access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :oa_id, presence: true
  validates :oa_id, uniqueness: true

  def name
    'ZaloPersonal'
  end

  def send_message(user_id, message)
    images = message.attachments.to_a.select { |a| a.file_type == 'image' }
    other_attachments = message.attachments.to_a.reject { |a| a.file_type == 'image' }

    last_response = nil

    if images.any?
      last_response = send_images(user_id, images, message.conversation.zalo_group?)
      if last_response && last_response['error'].to_i.zero?
        additional_attributes = message.additional_attributes || {}
        additional_attributes['attachment_msg_id'] = last_response.dig('data', 'message_id')
        message.update_columns(additional_attributes: additional_attributes)
      end
    end

    other_attachments.each do |attachment|
      last_response = send_attachment(user_id, attachment, message.conversation.zalo_group?)
      next unless last_response && last_response['error'].to_i.zero?

      additional_attributes = message.additional_attributes || {}
      additional_attributes['attachment_msg_id'] = last_response.dig('data', 'message_id')
      message.update_columns(additional_attributes: additional_attributes)
    end

    return last_response if message.content.blank? && last_response

    body = message_body(user_id, message)
    send_message_cs(body)
  end

  def refresh_access_token(channel)
    {
      'access_token' => channel.oa_access_token
    }
  end

  def send_text_message(user_id, content)
    body = {
      threadId: user_id,
      message: content,
      type: 0,
      ownId: oa_id
    }

    send_message_cs(body)
  end

  def send_message_cs(body)
    res = HTTParty.post(
      url_message_cs,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
    if res['error'].present? && res['error'].to_s != '0'
      Rails.logger.error "ZaloPersonal send_message_cs error: #{res['message']}"
      check_disconnection!
      { 'error' => 1, 'message' => res['message'] || res['error'] }
    else
      msg_id = res.dig('data', 'message', 'msgId') || res.dig('data', 'message_id')
      { 'error' => 0, 'data' => { 'message_id' => msg_id } }
    end
  end

  # Verifies connection health by calling getUserInfo API on the wrapper.
  # If the wrapper confirms disconnection, marks the channel for reauthorization.
  def check_disconnection!
    return if reauthorization_required?

    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      body: { userId: oa_id, ownId: oa_id }.to_json,
      headers: ZaloPersonal::ApiHelper.request_headers,
      timeout: 10
    )

    if response['error'].present? && response['error'].to_s != '0'
      Rails.logger.warn "ZaloPersonal channel #{id} disconnected: #{response['error']}"
      prompt_reauthorization!
    end
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal check_disconnection! failed for channel #{id}: #{e.message}"
    raise
  end

  def setup_webhooks
    webhook_url = "#{ENV.fetch('FRONTEND_URL', '')}/webhooks/zalo_personal"

    body = {
      ownId: oa_id,
      messageWebhookUrl: webhook_url,
      groupEventWebhookUrl: webhook_url,
      reactionWebhookUrl: webhook_url
    }

    HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/account-webhook",
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal setup_webhooks failed for channel #{id}: #{e.message}"
  end

  def teardown_webhooks
    HTTParty.delete(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/account-webhook/#{oa_id}",
      headers: ZaloPersonal::ApiHelper.request_headers
    )
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal teardown_webhooks failed for channel #{id}: #{e.message}"
  end

  # --- Zalo Reminder Sync ---

  def sync_create_reminder(conversation)
    payload = build_reminder_payload(conversation)
    res = call_zalo_api('/api/createReminder', payload)
    reminder_id = res.dig('data', 'reminderId') || res.dig('data', 'id')
    return unless reminder_id

    attrs = conversation.custom_attributes.merge('zalo_reminder_id' => reminder_id)
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(custom_attributes: attrs)
    # rubocop:enable Rails/SkipsModelValidations
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal sync_create_reminder failed: #{e.message}"
  end

  def sync_edit_reminder(conversation)
    reminder_id = conversation.custom_attributes['zalo_reminder_id']
    return unless reminder_id

    thread_id = conversation.contact_inbox&.source_id
    payload = {
      ownId: oa_id,
      threadId: thread_id,
      type: conversation.additional_attributes['type'] || 0,
      payload: {
        reminderId: reminder_id,
        content: conversation.reminder_note.presence || 'Nhắc hẹn',
        reminderTime: (conversation.reminder_at.to_i * 1000)
      }
    }

    call_zalo_api('/api/editReminder', payload)
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal sync_edit_reminder failed: #{e.message}"
  end

  def sync_remove_reminder(conversation)
    reminder_id = conversation.custom_attributes['zalo_reminder_id']
    return unless reminder_id

    thread_id = conversation.contact_inbox&.source_id
    payload = {
      ownId: oa_id,
      threadId: thread_id,
      type: conversation.additional_attributes['type'] || 0,
      reminderId: reminder_id
    }
    res = call_zalo_api('/api/removeReminder', payload)

    return unless res['success']

    attrs = conversation.custom_attributes.except('zalo_reminder_id')
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(custom_attributes: attrs)
    # rubocop:enable Rails/SkipsModelValidations
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal sync_remove_reminder failed: #{e.message}"
  end

  private

  def build_reminder_payload(conversation)
    thread_id = conversation.contact_inbox&.source_id
    remind_before = conversation.reminder_remind_before == 1 ? 60 : 0
    {
      ownId: oa_id,
      threadId: thread_id,
      type: conversation.additional_attributes['type'] || 0,
      payload: {
        content: conversation.reminder_note.presence || 'Nhắc hẹn',
        reminderTime: (conversation.reminder_at.to_i * 1000),
        repeat: Conversation.reminder_repeats[conversation.reminder_repeat] || 0,
        remindBefore: remind_before
      }
    }
  end

  def call_zalo_api(path, body)
    HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}#{path}",
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def url_message_cs
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendmessage"
  end

  def send_image_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendImage"
  end

  def send_images_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendImages"
  end

  def send_file_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendFile"
  end

  def send_video_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendVideo"
  end

  def send_voice_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendVoice"
  end

  def send_sticker_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendSticker"
  end

  def send_link_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendLink"
  end

  def send_card_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendCard"
  end

  def add_reaction_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/addReaction"
  end

  def send_attachment(user_id, attachment, is_zalo_group)
    method = case attachment.file_type.to_s
             when 'image'
               :send_image
             when 'video'
               :send_video
             when 'audio'
               :send_voice
             when 'sticker'
               :send_sticker
             when 'share'
               :send_link
             when 'contact'
               :send_card
             else
               :send_file
             end

    response = send(method, user_id, attachment, is_zalo_group)

    if response['error'].present? && response['error'].to_s != '0'
      Rails.logger.error "ZaloPersonal file error: #{response['message']}"
      check_disconnection!
      { 'error' => 1, 'message' => response['message'] || response['error'] }
    else
      msg_id = response.dig('data', 'attachment', 0, 'msgId') ||
               response.dig('data', 'message_id') ||
               response.dig('data', 'message', 'msgId')
      { 'error' => 0, 'data' => { 'message_id' => msg_id } }
    end
  end

  def send_file(user_id, attachment, is_zalo_group)
    body = {
      ownId: oa_id,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      filePath: attachment.proxy_url.presence || attachment.download_url || '',
      fileName: attachment.file.filename.to_s,
      filename: attachment.file.filename.to_s
    }

    HTTParty.post(
      send_file_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def send_image(user_id, attachment, is_zalo_group)
    image_path = attachment.proxy_url.presence || attachment.download_url || ''

    body = {
      ownId: oa_id,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      imagePath: image_path
    }

    response = HTTParty.post(
      send_image_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    if response['error'].present? && response['error'].to_s != '0'
      Rails.logger.error "ZaloPersonal send_image error: #{response['message']}"
      check_disconnection!
      { 'error' => 1, 'message' => response['message'] || response['error'] }
    else
      msg_id = response.dig('data', 'attachment', 0, 'msgId') ||
               response.dig('data', 'message_id') ||
               response.dig('data', 'message', 'msgId')
      { 'error' => 0, 'data' => { 'message_id' => msg_id } }
    end
  end

  def send_images(user_id, attachments, is_zalo_group)
    image_paths = attachments.map { |att| att.proxy_url.presence || att.download_url || '' }

    body = {
      ownId: oa_id,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      imagePaths: image_paths
    }

    response = HTTParty.post(
      send_images_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    if response['error'].present? && response['error'].to_s != '0'
      Rails.logger.error "ZaloPersonal send_images error: #{response['message']}"
      check_disconnection!
      { 'error' => 1, 'message' => response['message'] || response['error'] }
    else
      msg_id = response.dig('data', 'attachment', 0, 'msgId') ||
               response.dig('data', 'message_id') ||
               response.dig('data', 'message', 'msgId')
      { 'error' => 0, 'data' => { 'message_id' => msg_id } }
    end
  end

  def send_video(user_id, attachment, is_zalo_group)
    body = {
      ownId: oa_id,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      videoUrl: attachment.proxy_url.presence || attachment.download_url || '',
      fileName: attachment.file.filename.to_s,
      filename: attachment.file.filename.to_s,
      thumbnailUrl: attachment.thumb_url || '',
      msg: attachment.message&.content || ''
    }

    HTTParty.post(
      send_video_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def send_voice(user_id, attachment, is_zalo_group)
    # FIXME: API zca-js (v2.1.2) có bug khi xử lý URL trong sendVoice ("Unable to get voice content: Invalid URL").
    # Tạm thời fallback gửi file audio dưới dạng file đính kèm thông thường.
    send_file(user_id, attachment, is_zalo_group)
  end

  def send_sticker(user_id, attachment, is_zalo_group)
    sticker_id = attachment.meta&.dig('sticker_id') || attachment.meta&.dig('id') || attachment.external_url.to_i
    cate_id = attachment.meta&.dig('cate_id') || attachment.meta&.dig('cateId') || 0
    sticker_type = attachment.meta&.dig('sticker_type') || attachment.meta&.dig('type') || 1

    body = {
      ownId: oa_id,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      sticker: {
        id: sticker_id.to_i,
        cateId: cate_id.to_i,
        type: sticker_type.to_i
      }
    }

    HTTParty.post(
      send_sticker_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def send_link(user_id, attachment, is_zalo_group)
    body = {
      ownId: oa_id,
      threadId: user_id || '',
      type: is_zalo_group ? 1 : 0,
      linkUrl: attachment.external_url.presence || attachment.proxy_url.presence || attachment.download_url || '',
      msg: attachment.message&.content || ''
    }

    HTTParty.post(
      send_link_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def send_card(user_id, attachment, is_zalo_group)
    phone = attachment.meta&.dig('phone_number') || attachment.fallback_title || ''
    contact_id = attachment.meta&.dig('user_id') || ''

    body = {
      ownId: oa_id,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      userId: contact_id,
      phoneNumber: phone
    }

    HTTParty.post(
      send_card_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def add_reaction(user_id, message_id, cli_msg_id, reaction_icon = '👍', is_zalo_group = false)
    body = {
      ownId: oa_id,
      threadId: user_id || '',
      type: is_zalo_group ? 1 : 0,
      msgId: message_id || '',
      cliMsgId: cli_msg_id || '',
      icon: reaction_icon || ''
    }

    HTTParty.post(
      add_reaction_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def message_body(user_id, message)
    payload = {
      threadId: user_id,
      message: message.content,
      type: message.conversation.additional_attributes['type'] || 0,
      ownId: oa_id
    }
    return payload unless message.in_reply_to

    message_reply = Message.find_by(id: message.in_reply_to)
    return payload if message_reply.blank? || message_reply.additional_attributes['ttl'].blank?

    payload[:quoteMessage] = {
      content: message_reply.content,
      msgType: message_reply.additional_attributes['msgType'],
      propertyExt: message_reply.additional_attributes['propertyExt'],
      uidFrom: message_reply.additional_attributes['user_id'],
      msgId: message_reply.additional_attributes['msgId'],
      cliMsgId: message_reply.additional_attributes['cliMsgId'],
      ts: message_reply.additional_attributes['ts'],
      ttl: message_reply.additional_attributes['ttl']
    }

    payload
  end
end
