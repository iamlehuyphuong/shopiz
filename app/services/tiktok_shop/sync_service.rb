class TiktokShop::SyncService
  def initialize(channel)
    @channel = channel
    @inbox = channel.inbox
    @client = channel.client
  end

  def perform
    sync_conversations
  end

  private

  def sync_conversations
    # Fetch latest 20 conversations for now
    response = @client.get_conversations(page_size: 20)
    return unless response['code']&.zero?

    # Defensive parsing for both list-style and single-object responses
    conversations = response.dig('data', 'conversations') || []
    conversations = [response['data']] if conversations.empty? && response.dig('data', 'conversation_id')

    conversations.each do |conv_data|
      sync_messages(conv_data['conversation_id'])
    end
  end

  def sync_messages(conversation_id)
    response = @client.get_messages(conversation_id, page_size: 20)
    return unless response['code']&.zero?

    messages = response.dig('data', 'messages') || []
    # Reverse to process oldest first to maintain correct sequence in Chatwoot
    messages.reverse_each do |msg_data|
      process_message(conversation_id, msg_data)
    end
  end

  def process_message(conversation_id, msg_data)
    # Wrap message data to match IncomingMessageService format
    payload = {
      shop_id: @channel.shop_id,
      data: msg_data.merge(conversation_id: conversation_id)
    }.with_indifferent_access

    ::TiktokShop::IncomingMessageService.new(inbox: @inbox, params: payload).perform
  rescue StandardError => e
    Rails.logger.error "TiktokShop::SyncService error: #{e.message}"
  end
end
