class ZaloPersonal::SendOnZaloService < Base::SendOnChannelService
  private

  def channel_class
    Channel::ZaloPersonal
  end

  def perform_reply
    response = send_message
  end

  def send_message
    response = channel.send_message(message.conversation.contact_inbox.source_id, message, channel.oa_access_token)
    if (response['error']).zero? && response['data']['message_id']
      message.update!(status: :delivered, source_id: response['data']['message_id'])
    else
      message.update!(status: :failed, external_error: response['message'])
    end
    response
  end
end
