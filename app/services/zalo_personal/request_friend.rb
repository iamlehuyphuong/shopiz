class ZaloPersonal::RequestFriend
  def initialize(inbox_id, phone_number)
    @inbox = Inbox.find_by(id: inbox_id)
    @phone_number = phone_number
  end

  def execute
    return { status: false } unless @inbox&.zalo_personal?
    return { status: false } unless uid = load_user_id

    body = {
      userId: uid,
      ownId: @inbox.channel.oa_id
    }

    response = HTTParty.post(
      request_friend_url,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )

    { status: true || response['success'] }
  end

  def load_user_id
    body = {
      phone: @phone_number,
      ownId: @inbox.channel.oa_id
    }

    res = HTTParty.post(
      info_url,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )
    return unless res['success']

    res['data']['uid']
  end

  def info_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/findUser"
  end

  def request_friend_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendFriendRequest"
  end
end
