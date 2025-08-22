class Tiktok::SendOnTiktokService < Base::SendOnChannelService
  INVALID_ACCESS_TOKEN_CODE = 36009004
  private

  def channel_class
    Channel::Tiktok
  end

  def perform_reply
    response = send_message
    return unless response["code"] == INVALID_ACCESS_TOKEN_CODE

    result = channel.refresh_access_token
    if result["code"]&.zero?
      send_message
    else
      message.update!(status: :failed, external_error: result["message"])
    end
  end

    def send_message
    response = channel.send_message(message)

    if response["code"]&.zero?
      message.update!(source_id: response["data"]["message_id"])
    else
      message.update!(status: :failed, external_error: response["message"])
    end
    response
  end
end
