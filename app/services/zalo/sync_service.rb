# Syncs recent conversations and messages from Zalo OA to Shopiz
# Uses Zalo::Client for all API calls
class Zalo::SyncService
  attr_reader :inbox

  def initialize(inbox)
    @inbox = inbox
  end

  def perform
    conversations = client.list_recent_chats
    return if conversations['error'] && conversations['error'] != 0

    conversations['data'].each do |conv|
      sync_messages(conv['src_id']) # src_id is the user_id in Zalo
    end
  end

  private

  def channel
    @inbox.channel
  end

  def client
    @client ||= channel.client
  end

  def sync_messages(user_id)
    response = client.get_conversation(user_id)
    return if response['error'] && response['error'] != 0

    response['data'].reverse_each do |msg|
      process_message(user_id, msg)
    end
  end

  def process_message(user_id, msg)
    is_incoming = msg['src_id'] == user_id
    sender_id = is_incoming ? user_id : channel.oa_id

    message_params = {
      event_name: is_incoming ? 'user_send_text' : 'oa_send_text',
      sender: { id: sender_id },
      recipient: { id: is_incoming ? channel.oa_id : user_id },
      message: {
        text: msg['message'],
        msg_id: msg['message_id']
      },
      timestamp: msg['timestamp']
    }

    if is_incoming
      Zalo::IncomingMessageService.new(inbox: @inbox, params: message_params.with_indifferent_access).perform
    else
      Zalo::OutgoingMessageService.new(inbox: @inbox, params: message_params.with_indifferent_access).perform
    end
  end
end
