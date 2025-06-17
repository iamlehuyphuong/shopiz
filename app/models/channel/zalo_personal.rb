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
  
    def send_message(user_id, message, access_token)
      # check attachment to send first
      if message.attachments&.first
        response = send_attachment(user_id, message.attachments.first)
        return response unless (response['error']).zero?
      end
  
      # message content will come separately
      return unless message.content
  
      body = message_body(user_id, message)
      send_message_cs(body)
    end
  
    def refresh_access_token(channel)
      response = {
        'access_token' => channel.oa_access_token,
      }
      response
    end
  
    def send_message_cs(body)
      res = HTTParty.post(
        url_message_cs,
        headers: { 'Content-Type' => 'application/json' },
        body: body.to_json
      )
      if res['error'].present?
        Rails.logger.error "ZaloPersonal send_message_cs error: #{res['message']}"
        { 'error' => 1, 'message' => res['message'] }
      else
        { 'error' => 0, 'data' => { 'message_id' => res['data']['message_id'] } }
      end
    end
  
    private
  
    def url_message_cs
      "#{ENV['ZALO_API_URL']}/api/sendmessage"
    end
  
    def url_upload_file
      '#{ENV['ZALO_API_URL']}/api/sendImageToUser'
    end
  
    def url_upload_image
      '#{ENV['ZALO_API_URL']}/api/sendImageToUser'
    end
  
    def send_attachment(user_id, attachment, access_token)
      is_image = attachment.file_type == 'image'
      url_upload = is_image ? url_upload_image : url_upload_file
      return unless (response = upload_file_to_zalo_api(url_upload, attachment, access_token)).zero?
  
      data = JSON.parse(response.body)
      return data unless (data['error']).zero?
  
      body = is_image ? image_body(user_id, data['data']['attachment_id']) : attachment_body(user_id, data['data']['token'])
      send_message_cs(body)
    end
  
    # unknown issue with HTTParty so changed to Net::HTTP with success
    def upload_file_to_zalo_api(url_upload, attachment, access_token)
      url = URI.parse(url_upload)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
  
      request = Net::HTTP::Post.new(url.path)
      request['access_token'] = access_token
      request.content_type = 'multipart/form-data'
      request.set_form([
                         ['file', attachment.file.download, { filename: attachment.file.filename.to_s }]
                       ], 'multipart/form-data')
  
      http.request(request)
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
  
    def message_body(user_id, message)
      {
        threadId: user_id,
        message: message.content,
        type: message.conversation.additional_attributes["type"] || 0,
        ownId: self.oa_id,
      }
    end
  end