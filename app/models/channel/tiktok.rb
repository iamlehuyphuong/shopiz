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

class Channel::Tiktok < ApplicationRecord
  include Channelable

  self.table_name = 'channel_tiktok'
  EDITABLE_ATTRS = [:access_token, :refresh_token, :expires_in].freeze
  INVALID_ACCESS_TOKEN_CODE = 36_009_004

  validates :access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :shop_id, presence: true, uniqueness: true
  validates :shop_cipher, presence: true, uniqueness: true

  def name
    'Tiktok'
  end

  def send_message(message)
    source_conversation_id = message.source_conversation_id
    if (attachment = message.attachments&.first) && attachment&.file_type == 'image'
      result = send_image(source_conversation_id, attachment)
      return result unless result['code']&.zero?
    end
    return {} unless message.content

    text_body = build_text_body(message.content)
    call_api_send_message(source_conversation_id, text_body)
  end

  def refresh_access_token
    refresh_url = 'https://auth.tiktok-shops.com/api/v2/token/refresh'
    params = {
      app_key: GlobalConfigService.load('TIKTOK_APP_ID', ''),
      app_secret: GlobalConfigService.load('TIKTOK_APP_SECRET', ''),
      refresh_token: refresh_token,
      grant_type: 'refresh_token'
    }
    url = "#{refresh_url}?#{URI.encode_www_form(params)}"
    response = HTTParty.get(url)
    result = JSON.parse(response.body)

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
    converstation_messages_url = "https://open-api.tiktokglobalshop.com/customer_service/202309/conversations/#{conversation_id}/messages"
    params = default_params.merge(options)

    signed_url = ::Tiktok::SignatureService.signed_url(
      converstation_messages_url,
      params: params,
      content_type: 'application/json'
    )
    res = HTTParty.get(
      signed_url,
      headers: { 'content-type' => 'application/json', 'x-tts-access-token' => access_token }
    )

    JSON.parse(res.body)
  end

  private

  def send_image(source_conversation_id, attachment)
    result = upload_image_to_tiktok(attachment)
    return result unless result['code']&.zero?

    image_body = {
      type: 'IMAGE',
      content: {
        url: result.dig('data', 'url'),
        width: result.dig('data', 'width'),
        height: result.dig('data', 'height')
      }.to_json
    }.to_json

    call_api_send_message(source_conversation_id, image_body)
  end

  def upload_image_to_tiktok(attachment)
    upload_image_url = 'https://open-api.tiktokglobalshop.com/customer_service/202309/images/upload'
    signed_url = ::Tiktok::SignatureService.signed_url(
      upload_image_url,
      params: default_params,
      content_type: 'multipart/form-data'
    )

    uri = URI.parse(signed_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['x-tts-access-token'] = access_token
    request['content-type'] = 'multipart/form-data'

    request.set_form(
      [
        ['data', attachment.file.download]
      ]
    )

    res = http.request(request)
    JSON.parse(res.body)
  end

  def call_api_send_message(conversation_id, body)
    send_message_url = "https://open-api.tiktokglobalshop.com/customer_service/202309/conversations/#{conversation_id}/messages"
    signed_url = ::Tiktok::SignatureService.signed_url(
      send_message_url,
      params: default_params,
      body: body,
      content_type: 'application/json'
    )
    res = HTTParty.post(
      signed_url,
      headers: { 'content-type' => 'application/json', 'x-tts-access-token' => access_token },
      body: body
    )

    JSON.parse(res.body)
  end

  def default_params
    {
      app_key: GlobalConfigService.load('TIKTOK_APP_ID', ''),
      shop_cipher: shop_cipher,
      timestamp: Time.now.to_i
    }
  end

  def build_text_body(text_content)
    {
      type: 'TEXT',
      content: { content: text_content }.to_json
    }.to_json
  end
end
