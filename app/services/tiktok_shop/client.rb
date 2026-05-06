class TiktokShop::Client
  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  def send_message(conversation_id, body)
    post("conversations/#{conversation_id}/messages", body: body)
  end

  def upload_image(image_data)
    post('images/upload', body: image_data, content_type: 'multipart/form-data')
  end

  def get_authorized_shops
    url = 'https://open-api.tiktokglobalshop.com/authorization/202309/shops'
    params = default_params.except(:shop_cipher)
    signed_url = signature_service.signed_url(url, params: params)

    response = HTTParty.get(signed_url, headers: headers)
    JSON.parse(response.body)
  end

  def get_category_assets
    url = 'https://open-api.tiktokglobalshop.com/authorization/202405/category_assets'
    params = default_params.except(:shop_cipher)
    signed_url = signature_service.signed_url(url, params: params)

    response = HTTParty.get(signed_url, headers: headers)
    JSON.parse(response.body)
  end

  def get_conversation(conversation_id)
    get("conversations/#{conversation_id}")
  end

  def mark_as_read(conversation_id)
    post("conversations/#{conversation_id}/messages/read", body: {}.to_json)
  end

  def create_conversation(buyer_user_id)
    body = { buyer_user_id: buyer_user_id }.to_json
    post('conversations', body: body)
  end

  def get_conversations(options = {})
    get('conversations', params: options)
  end

  def get_messages(conversation_id, options = {})
    get("conversations/#{conversation_id}/messages", params: options)
  end

  def refresh_token
    refresh_url = 'https://auth.tiktok-shops.com/api/v2/token/refresh'
    params = {
      app_key: tiktok_shop_app_key,
      app_secret: tiktok_shop_app_secret,
      refresh_token: channel.refresh_token,
      grant_type: 'refresh_token'
    }
    url = "#{refresh_url}?#{URI.encode_www_form(params)}"
    response = HTTParty.get(url)
    JSON.parse(response.body)
  end

  def get_message_templates
    url = 'https://open-api.tiktokglobalshop.com/customer_engagement/202412/message_templates'
    params = default_params.except(:shop_cipher)
    signed_url = signature_service.signed_url(url, params: params, content_type: 'application/json')
    
    response = HTTParty.get(signed_url, headers: headers)
    JSON.parse(response.body)
  end

  private

  def get(path, params: {})
    url = build_url(path)
    signed_url = signature_service.signed_url(url, params: default_params.merge(params), content_type: 'application/json')
    
    response = HTTParty.get(signed_url, headers: headers)
    JSON.parse(response.body)
  end

  def post(path, body: {}, params: {}, content_type: 'application/json')
    url = build_url(path)
    signed_url = signature_service.signed_url(
      url, 
      params: default_params.merge(params), 
      body: body, 
      content_type: content_type
    )

    if content_type == 'multipart/form-data'
      send_multipart_post(signed_url, body)
    else
      response = HTTParty.post(signed_url, headers: headers(content_type), body: body)
      JSON.parse(response.body)
    end
  end

  def build_url(path)
    "https://open-api.tiktokglobalshop.com/customer_service/202309/#{path}"
  end

  def headers(content_type = 'application/json')
    {
      'content-type' => content_type,
      'x-tts-access-token' => channel.access_token
    }
  end

  def default_params
    {
      app_key: tiktok_shop_app_key,
      shop_cipher: channel.shop_cipher,
      timestamp: Time.now.to_i
    }
  end

  def signature_service
    ::TiktokShop::SignatureService
  end

  def tiktok_shop_app_key
    GlobalConfigService.load('TIKTOK_SHOP_APP_KEY', '')
  end

  def tiktok_shop_app_secret
    GlobalConfigService.load('TIKTOK_SHOP_APP_SECRET', '')
  end

  def send_multipart_post(url, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path + "?" + uri.query)
    request['x-tts-access-token'] = channel.access_token
    request['content-type'] = 'multipart/form-data'
    request.set_form([['data', data]], 'multipart/form-data')

    res = http.request(request)
    JSON.parse(res.body)
  rescue StandardError => e
    { 'code' => -1, 'message' => e.message }
  end
end
