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

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :oa_access_token
    encrypts :refresh_token
  end

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

  def send_message(target_id, message, _access_token = nil)
    last_response = nil

    return send_template_message(target_id, message) if message.template?

    is_group = message.conversation.contact.custom_attributes['is_zalo_group']
    target_id_key = is_group ? :group_id : :user_id

    # Send attachments first
    message.attachments.each do |attachment|
      response = send_attachment(target_id, attachment, target_id_key, is_group)
      return response unless response['error']&.zero?

      last_response = response
    end

    if message.content.present?
      body = message_body(target_id, message.content, target_id_key)
      body[:message][:quote_message_id] = message.content_attributes[:in_reply_to_external_id] if message.content_attributes[:in_reply_to_external_id]

      return is_group ? client.send_group_message(body) : client.send_cs_message(body)
    end

    last_response
  end

  def refresh_access_token(channel)
    Zalo::TokenService.new(channel: channel).refresh!
    { 'access_token' => channel.reload.oa_access_token }
  end

  private

  def send_template_message(user_id, message)
    template_name = message.content_attributes['template_name']
    template_params = message.content_attributes['template_params'] || {}

    zalo_template = zalo_message_templates.find_by(template_name: template_name)
    return { 'error' => 1, 'message' => 'Template not found' } unless zalo_template

    payload = zalo_template.build_payload(user_id, template_params)

    if zalo_template.promotion?
      client.send_promotion_message(payload)
    else
      client.send_transaction_message(payload)
    end
  end

  def send_attachment(target_id, attachment, target_id_key = :user_id, is_group = false) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    is_image = attachment.file_type == 'image'
    is_gif = is_image && attachment.file.content_type == 'image/gif'
    file_data = attachment.file.download
    filename = attachment.file.filename.to_s

    data = if is_gif
             client.upload_gif(file_data, filename)
           elsif is_image
             client.upload_image(file_data, filename)
           else
             client.upload_file(file_data, filename)
           end

    return data unless data['error']&.zero?

    body = if is_image
             media_body(target_id, data['data']['attachment_id'], is_gif ? 'gif' : 'image', target_id_key)
           else
             attachment_body(target_id, data['data']['token'], target_id_key)
           end

    is_group ? client.send_group_message(body) : client.send_cs_message(body)
  end

  def attachment_body(target_id, file_token, target_id_key = :user_id)
    {
      recipient: { target_id_key => target_id },
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

  def media_body(target_id, attachment_id, media_type = 'image', target_id_key = :user_id)
    {
      recipient: { target_id_key => target_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'media',
            elements: [{
              media_type: media_type,
              attachment_id: attachment_id
            }]
          }
        }
      }
    }
  end

  def message_body(target_id, message_content, target_id_key = :user_id)
    {
      recipient: { target_id_key => target_id },
      message: { text: message_content }
    }
  end
end
