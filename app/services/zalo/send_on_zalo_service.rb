class Zalo::SendOnZaloService < Base::SendOnChannelService
  private

  def channel_class
    Channel::ZaloOa
  end

  def perform_reply
    response = send_message
    return unless response['error'] == Zalo::Client::TOKEN_EXPIRED_ERROR

    # Token auto-refresh is handled by Zalo::Client, but if it still fails
    # after retry, mark message as failed
    message.update!(status: :failed, external_error: 'Zalo OA token expired, reauthorization required')
  end

  def send_message
    response = channel.send_message(message.conversation.contact_inbox.source_id, message)
    if (response['error']).zero? && response['data']['message_id']
      message.update!(source_id: response['data']['message_id'])
    elsif response['error'] != Zalo::Client::TOKEN_EXPIRED_ERROR
      message.update!(status: :failed, external_error: response['message'])
    end
    response
  end
end
