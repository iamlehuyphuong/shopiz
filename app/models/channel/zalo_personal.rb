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
  
  EDITABLE_ATTRS = [:oa_access_token, :refresh_token, :expires_in, :default_friend_request_message, :default_greeting_message, { provider_config: {} }].freeze

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
    if attachment = message.attachments&.first
      response = send_attachment(user_id, attachment, message.conversation.zalo_group?)
      if (response['error']).zero?
        additional_attributes = message.additional_attributes
        additional_attributes['attachment_msg_id'] = response['data']['message_id']
        message.update_columns(additional_attributes: additional_attributes)
      end
    end
    return response unless message.content

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
    if res['error'].present?
      Rails.logger.error "ZaloPersonal send_message_cs error: #{res['message']}"
      check_disconnection!
      { 'error' => 1, 'message' => res['error'] }
    else
      { 'error' => 0, 'data' => { 'message_id' => res['data']['message']['msgId'] } }
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

    if response['error'].present?
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

  private

  def url_message_cs
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendmessage"
  end

  def send_image_to_user_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendImageToUser"
  end

  def send_image_to_group_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendImageToGroup"
  end

  def send_file_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendFile"
  end

  def send_attachment(user_id, attachment, is_zalo_group)
    method = attachment.file_type == 'image' ? :send_image : :send_file
    response = send(method, user_id, attachment, is_zalo_group)

    if response['error'].present?
      Rails.logger.error "ZaloPersonal file error: #{response['message']}"
      check_disconnection!
      { 'error' => 1, 'message' => response['error'] }
    else
      { 'error' => 0, 'data' => { 'message_id' => response['data']['attachment'][0]['msgId'] } }
    end
  end

  def send_file(user_id, attachment, is_zalo_group)
    body = {
      filePath: attachment.file_url,
      threadId: user_id,
      type: is_zalo_group ? 1 : 0,
      ownId: oa_id
    }

    HTTParty.post(
      send_file_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
  end

  def send_image(user_id, attachment, is_zalo_group)
    url_upload = is_zalo_group ? send_image_to_group_url : send_image_to_user_url

    body = {
      imagePath: attachment.file_url,
      threadId: user_id,
      ownId: oa_id
    }

    HTTParty.post(
      url_upload,
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
