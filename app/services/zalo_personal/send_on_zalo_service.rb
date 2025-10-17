class ZaloPersonal::SendOnZaloService < Base::SendOnChannelService
  private

  def channel_class
    Channel::ZaloPersonal
  end

  def perform_reply
    response = channel.send_message(message.conversation.contact_inbox.source_id, message)
    if (response['error']).zero? && response['data']['message_id']
      message.update!(status: :delivered, source_id: response['data']['message_id'])
    else
      message.update!(status: :failed, external_error: response['message'])
    end
    response
  end
end
