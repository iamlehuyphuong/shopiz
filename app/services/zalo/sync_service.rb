class Zalo::SyncService
  attr_reader :inbox

  def initialize(inbox)
    @inbox = inbox
  end

  def perform
    conversations = recent_chats
    return if conversations['error'] && conversations['error'] != 0

    conversations['data'].each do |conv|
      sync_messages(conv['src_id']) # src_id is the user_id in Zalo
    end
  end

  private

  def channel
    @inbox.channel
  end

  def recent_chats
    # Zalo OA V2 api for list recent chat
    HTTParty.get(
      'https://openapi.zalo.me/v2.0/oa/listrecentchat',
      headers: { 'access_token' => channel.oa_access_token },
      query: { data: { offset: 0, count: 50 }.to_json }
    )
  end

  def sync_messages(user_id)
    response = HTTParty.get(
      'https://openapi.zalo.me/v2.0/oa/conversation',
      headers: { 'access_token' => channel.oa_access_token },
      query: { data: { user_id: user_id, offset: 0, count: 20 }.to_json }
    )

    return if response['error'] && response['error'] != 0

    response['data'].reverse_each do |msg|
      process_message(user_id, msg)
    end
  end

  def process_message(user_id, msg)
    # Map Zalo message to Chatwoot message format
    # Zalo message object: { message_id, src_id, text, type, timestamp, ... }
    # msg['src_id'] matches user_id if it's incoming, else it's the OA (outgoing)

    is_incoming = msg['src_id'] == user_id
    sender_id = is_incoming ? user_id : channel.oa_id

    # Reuse OutgoingMessageService or IncomingMessageService by forging params
    # However, those services expect Webhook payload.
    # For sync, it's cleaner to handle it here or in a specialized sync processor.

    # For now, let's just use the existing services if possible by adapting params
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
      # We don't want to sync echo messages if they are already in the system,
      # but OutgoingMessageService handles deduplication via source_id.
      Zalo::OutgoingMessageService.new(inbox: @inbox, params: message_params.with_indifferent_access).perform
    end
  end
end
