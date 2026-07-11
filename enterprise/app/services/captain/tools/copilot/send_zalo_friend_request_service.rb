class Captain::Tools::Copilot::SendZaloFriendRequestService < Captain::Tools::BaseTool
  def self.name
    'send_zalo_friend_request'
  end

  def self.description
    'Sends a Zalo friend request to a customer phone number along with an optional greeting message.'
  end

  def self.parameters
    {
      type: 'object',
      properties: {
        phone_number: {
          type: 'string',
          description: 'The phone number of the customer in Zalo format (e.g. 0912345678 or 84912345678).'
        },
        message: {
          type: 'string',
          description: 'The greeting message to send along with the friend request.'
        }
      },
      required: %w[phone_number message]
    }
  end

  def execute(arguments)
    phone_number = arguments['phone_number']

    zalo_inbox = @account.inboxes.where(channel_type: 'Channel::ZaloPersonal').sample

    # In case there's no active connection, fallback to active scope if possible, or any.
    return { status: false, error: 'No active Zalo Personal account found.' } unless zalo_inbox

    message = arguments['message'].presence || zalo_inbox.greeting_message.presence || 'Chào bạn, mình là tư vấn viên từ hệ thống.'
    result = ZaloPersonal::RequestFriend.new(
      inbox_id: zalo_inbox.id,
      source_id: phone_number,
      message: message
    ).execute

    if result[:status]
      { status: true, message: 'Friend request sent successfully.' }
    else
      { status: false, error: result[:error] || 'Failed to send friend request. User might already be a friend or invalid number.' }
    end
  rescue StandardError => e
    { status: false, error: e.message }
  end

  def active?
    @account.inboxes.where(channel_type: 'Channel::ZaloPersonal').exists?
  end
end
