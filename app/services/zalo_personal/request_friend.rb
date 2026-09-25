class ZaloPersonal::RequestFriend
  def initialize(params)
    @inbox = Inbox.find_by(id: params[:inbox_id])
    @phone_number = params[:source_id]
    @message = params[:message]
  end

  def execute
    return { status: false } unless @inbox&.zalo_personal?

    user_info = load_user_info
    return { status: false } unless user_info

    return { status: true, already_friend: true } if user_info['isFr']

    body = {
      userId: user_info['uid'],
      ownId: @inbox.channel.oa_id,
      message: @message
    }

    response = HTTParty.post(
      request_friend_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    { status: response['success'] }
  end

  def load_user_info
    body = {
      phone: @phone_number,
      ownId: @inbox.channel.oa_id
    }

    res = HTTParty.post(
      info_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
    return unless res['success']

    res['data']
  end

  def info_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/findUser"
  end

  def request_friend_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/sendFriendRequest"
  end
end
