# == Schema Information
#
# Table name: channel_tiktok
#
#  id            :bigint           not null, primary key
#  access_token  :string           not null
#  expires_in    :integer          not null
#  refresh_token :string           not null
#  shop_cipher   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  shop_id       :string           not null
#
# Indexes
#
#  index_channel_tiktok_on_shop_cipher  (shop_cipher) UNIQUE
#  index_channel_tiktok_on_shop_id      (shop_id) UNIQUE
#

class Channel::TiktokShop < ApplicationRecord
  include Channelable
  include Reauthorizable

  encrypts :access_token
  encrypts :refresh_token

  self.table_name = 'channel_tiktok_shop'
  EDITABLE_ATTRS = [:access_token, :refresh_token, :expires_in].freeze
  INVALID_ACCESS_TOKEN_CODE = 36_009_004

  validates :access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :shop_id, presence: true, uniqueness: true
  validates :shop_cipher, presence: true, uniqueness: true

  def name
    'Tiktok Shop'
  end

  def client
    @client ||= TiktokShop::Client.new(self)
  end

  def send_message(message)
    source_conversation_id = message.source_conversation_id
    if (attachment = message.attachments&.first) && attachment&.file_type == 'image'
      result = send_image(source_conversation_id, attachment)
      return result unless result['code']&.zero?
    end
    return {} unless message.content

    text_body = build_text_body(message.content)
    client.send_message(source_conversation_id, text_body)
  end

  def refresh_access_token
    result = client.refresh_token

    if result['code']&.zero?
      update!(
        access_token: result.dig('data', 'access_token'),
        refresh_token: result.dig('data', 'refresh_token'),
        expires_in: result.dig('data', 'access_token_expire_in')
      )
    end

    result
  end

  def get_conversation_messages(conversation_id, options)
    client.get_messages(conversation_id, options)
  end

  private

  def send_image(source_conversation_id, attachment)
    result = client.upload_image(attachment.file.download)
    return result unless result['code']&.zero?

    image_body = {
      type: 'IMAGE',
      content: {
        url: result.dig('data', 'url'),
        width: result.dig('data', 'width'),
        height: result.dig('data', 'height')
      }.to_json
    }.to_json

    client.send_message(source_conversation_id, image_body)
  end

  def build_text_body(text_content)
    {
      type: 'TEXT',
      content: { content: text_content }.to_json
    }.to_json
  end
end
