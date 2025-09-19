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

  self.table_name = 'channel_zalo_personal'
  EDITABLE_ATTRS = [:oa_access_token, :refresh_token, :expires_in].freeze

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
      return send_attachment(user_id, attachment, message.conversation.zalo_group?)
    end
    return unless message.content

    body = message_body(user_id, message)
    send_message_cs(body)
  end

  def refresh_access_token(channel)
    {
      'access_token' => channel.oa_access_token
    }
  end

  def send_message_cs(body)
    res = HTTParty.post(
      url_message_cs,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )
    if res['error'].present?
      Rails.logger.error "ZaloPersonal send_message_cs error: #{res['message']}"
      { 'error' => 1, 'message' => res['error'] }
    else
      { 'error' => 0, 'data' => { 'message_id' => res['data']['message']['msgId'] } }
    end
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

  def send_attachment(user_id, attachment, is_zalo_group)
    return {} if attachment.file_type != 'image'

    url_upload = is_zalo_group ? send_image_to_group_url : send_image_to_user_url
    response = send_image(user_id, url_upload, attachment)

    if response['error'].present?
      Rails.logger.error "ZaloPersonal image error: #{response['message']}"
      { 'error' => 1, 'message' => response['error'] }
    else
      { 'error' => 0, 'data' => { 'message_id' => response['data']['attachment'][0]['msgId'] } }
    end
  end

  def send_image(user_id, url_upload, attachment)
    body = {
      imagePath: attachment.file_url,
      threadId: user_id,
      ownId: oa_id
    }

    res = HTTParty.post(
      url_upload,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )
  end

  def message_body(user_id, message)
    {
      threadId: user_id,
      message: message.content,
      type: message.conversation.additional_attributes['type'] || 0,
      ownId: oa_id
    }
  end
end
