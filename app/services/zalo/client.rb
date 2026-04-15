# Centralized HTTP client for all Zalo OA API interactions
# Handles token management, request/response, and error handling
class Zalo::Client
  BASE_URL = 'https://openapi.zalo.me'.freeze
  OAUTH_URL = 'https://oauth.zaloapp.com'.freeze

  TOKEN_EXPIRED_ERROR = -216

  pattr_initialize [:channel!]

  # --- User / Follower APIs ---

  def get_user_detail(user_id)
    get('/v3.0/oa/user/detail', query: { data: { user_id: user_id }.to_json })
  end

  def get_followers(offset: 0, count: 50)
    get('/v2.0/oa/getfollowers', query: { data: { offset: offset, count: count }.to_json })
  end

  def tag_follower(user_id, tag_name)
    post('/v3.0/oa/tag/tagfollower', body: { user_id: user_id, tag_name: tag_name })
  end

  # --- Messaging APIs ---

  def send_cs_message(body)
    post('/v3.0/oa/message/cs', body: body)
  end

  def send_transaction_message(body)
    post('/v3.0/oa/message/transaction', body: body)
  end

  def send_promotion_message(body)
    post('/v3.0/oa/message/promotion', body: body)
  end

  # --- Media Upload APIs ---

  def upload_image(file, filename)
    upload('/v2.0/oa/upload/image', file, filename)
  end

  def upload_file(file, filename)
    upload('/v2.0/oa/upload/file', file, filename)
  end

  # --- Recent chats (for sync) ---

  def list_recent_chats(offset: 0, count: 50)
    get('/v2.0/oa/listrecentchat', query: { data: { offset: offset, count: count }.to_json })
  end

  def get_conversation(user_id, offset: 0, count: 20)
    get('/v2.0/oa/conversation', query: { data: { user_id: user_id, offset: offset, count: count }.to_json })
  end

  # --- Request User Info ---

  def request_user_info(user_id, subtitle: 'Chia sẻ thông tin', image_url: nil)
    body = {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'request_user_info',
            elements: [{
              title: 'Thông tin cá nhân',
              subtitle: subtitle,
              image_url: image_url
            }.compact]
          }
        }
      }
    }
    send_cs_message(body)
  end

  private

  def access_token
    @access_token ||= Zalo::TokenService.new(channel: channel).access_token
  end

  def default_headers
    {
      'Content-Type' => 'application/json',
      'access_token' => access_token
    }
  end

  def get(path, query: {})
    with_token_retry do
      HTTParty.get(
        "#{BASE_URL}#{path}",
        headers: { 'access_token' => access_token },
        query: query
      )
    end
  end

  def post(path, body: {})
    with_token_retry do
      HTTParty.post(
        "#{BASE_URL}#{path}",
        headers: default_headers,
        body: body.to_json
      )
    end
  end

  def upload(path, file, filename)
    url = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url.path)
    request['access_token'] = access_token
    request.content_type = 'multipart/form-data'
    request.set_form(
      [['file', file, { filename: filename }]],
      'multipart/form-data'
    )

    response = http.request(request)
    JSON.parse(response.body)
  end

  def with_token_retry
    response = yield
    return response unless response['error'] == TOKEN_EXPIRED_ERROR

    # Token expired, force refresh and retry once
    @access_token = Zalo::TokenService.new(channel: channel).refresh!
    yield
  end
end
