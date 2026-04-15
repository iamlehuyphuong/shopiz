# == Schema Information
#
# Table name: channel_zalo_oa
#
#  id              :bigint           not null, primary key
#  expires_in      :integer          not null
#  oa_access_token :string           not null
#  refresh_token   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  oa_id           :string           not null
#
# Indexes
#
#  index_channel_zalo_oa_on_oa_id  (oa_id) UNIQUE
#

class Channel::ZaloOa < ApplicationRecord
  include Channelable
  include Reauthorizable

  encrypts :oa_access_token
  encrypts :refresh_token

  self.table_name = 'channel_zalo_oa'
  EDITABLE_ATTRS = [:oa_access_token, :refresh_token, :expires_in].freeze

  validates :oa_access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :oa_id, presence: true
  validates :oa_id, uniqueness: true

  has_many :zalo_message_templates, dependent: :destroy_async, foreign_key: :channel_id

  def name
    'ZaloOa'
  end

  def client
    @client ||= Zalo::Client.new(channel: self)
  end

  def send_message(user_id, message, _access_token = nil)
    # Send attachments first
    message.attachments.each do |attachment|
      response = send_attachment(user_id, attachment)
      return response unless response['error']&.zero? && message.content
    end

    body = message_body(user_id, message.content)
    body[:message][:quote_message_id] = message.content_attributes[:in_reply_to_external_id] if message.content_attributes[:in_reply_to_external_id]
    client.send_cs_message(body)
  end

  def refresh_access_token(channel)
    Zalo::TokenService.new(channel: channel).refresh!
    { 'access_token' => channel.reload.oa_access_token }
  end

  private

  def send_attachment(user_id, attachment)
    is_image = attachment.file_type == 'image'
    file_data = attachment.file.download
    filename = attachment.file.filename.to_s

    data = if is_image
             client.upload_image(file_data, filename)
           else
             client.upload_file(file_data, filename)
           end

    return data unless data['error']&.zero?

    body = if is_image
             image_body(user_id, data['data']['attachment_id'])
           else
             attachment_body(user_id, data['data']['token'])
           end
    client.send_cs_message(body)
  end

  def attachment_body(user_id, file_token)
    {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'file',
          payload: {
            token: file_token
          }
        }
      }
    }
  end

  def image_body(user_id, attachment_id)
    {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'media',
            elements: [{
              media_type: 'image',
              attachment_id: attachment_id
            }]
          }
        }
      }
    }
  end

  def message_body(user_id, message_content)
    {
      recipient: { user_id: user_id },
      message: { text: message_content }
    }
  end
end
