class ZaloPersonal::RequestFriend
  def initialize(params)
    @inbox = Inbox.find_by(id: params[:inbox_id])
    @phone_number = params[:source_id]
    @message = params[:message]
  end

  def execute
    return { status: false } unless @inbox&.zalo_personal?
    return { status: false } unless uid = load_user_id

    body = {
      userId: uid,
      ownId: @inbox.channel.oa_id,
      message: @message
    }

    response = HTTParty.post(
      request_friend_url,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )

    { status: response['success'] }
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
    "#{GlobalConfigService.load('ZALO_OA_API_URL', nil)}/api/findUser"
  end

  def request_friend_url
    "#{GlobalConfigService.load('ZALO_OA_API_URL', nil)}/api/sendFriendRequest"
  end
end
