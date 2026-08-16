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
    get('/v3.0/oa/user/getlist', query: { data: { offset: offset, count: count }.to_json })
  end

  def get_tags
    get('/v2.0/oa/tag/gettagsofoa')
  end

  def remove_tag(tag_name)
    post('/v2.0/oa/tag/rmtag', body: { tag_name: tag_name })
  end

  def tag_follower(user_id, tag_name)
    post('/v3.0/oa/tag/tagfollower', body: { user_id: user_id, tag_name: tag_name })
  end

  def untag_follower(user_id, tag_name)
    post('/v2.0/oa/tag/untagfollower', body: { user_id: user_id, tag_name: tag_name })
  end

  def update_user_custom_info(user_id, body)
    payload = body.merge(user_id: user_id)
    post('/v3.0/oa/user/update/custominfo', body: payload)
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

  def upload_gif(file, filename)
    upload('/v2.0/oa/upload/gif', file, filename)
  end

  def upload_file(file, filename)
    upload('/v2.0/oa/upload/file', file, filename)
  end

  # --- Recent chats (for sync) ---

  def list_recent_chats(offset: 0, count: 50)
    get('/v2.0/oa/listrecentchat', query: { data: { offset: offset, count: count }.to_json })
  end

  def get_conversation(user_id = nil, offset: 0, count: 20, group_id: nil)
    data = { offset: offset, count: count }
    data[:user_id] = user_id if user_id
    data[:group_id] = group_id if group_id

    get('/v2.0/oa/conversation', query: { data: data.to_json })
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

  # --- GMF (Group Management Function) APIs ---

  def send_group_message(body)
    post('/v3.0/oa/group/message', body: body)
  end

  def create_group(body)
    post('/v3.0/oa/group/creategroupwithoa', body: body)
  end

  def get_group_info(group_id)
    get('/v3.0/oa/group/detail', query: { data: { group_id: group_id }.to_json })
  end

  def update_group_info(body)
    post('/v3.0/oa/group/update', body: body)
  end

  def delete_group(group_id)
    post('/v3.0/oa/group/deletegroup', body: { group_id: group_id })
  end

  def get_groups_of_oa(offset: 0, count: 50)
    get('/v3.0/oa/group/getgroupsofoa', query: { data: { offset: offset, count: count }.to_json })
  end

  def invite_member(body)
    post('/v3.0/oa/group/invite', body: body)
  end

  def get_pending_members(group_id, offset: 0, count: 50)
    get('/v3.0/oa/group/getlistpendingmember', query: { data: { group_id: group_id, offset: offset, count: count }.to_json })
  end

  def accept_member(body)
    post('/v3.0/oa/group/acceptpendingmember', body: body)
  end

  def reject_member(body)
    post('/v3.0/oa/group/rejectpendingmember', body: body)
  end

  def get_group_members(group_id, offset: 0, count: 50)
    get('/v3.0/oa/group/getlistmember', query: { data: { group_id: group_id, offset: offset, count: count }.to_json })
  end

  def remove_members(body)
    post('/v3.0/oa/group/removemember', body: body)
  end

  def add_group_admins(body)
    post('/v3.0/oa/group/addadmin', body: body)
  end

  def remove_group_admins(body)
    post('/v3.0/oa/group/removeadmin', body: body)
  end

  # --- ZNS / Template APIs ---

  def get_templates(offset: 0, limit: 100)
    with_token_retry do
      HTTParty.get(
        'https://business.openapi.zalo.me/template/all',
        headers: default_headers,
        query: { offset: offset, limit: limit }
      )
    end
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
