# Loads conversation history from TikTok Shop using the Customer Service API
# Uses cursor-based pagination (page_token) to iterate through all conversations
# Creates contacts, contact_inboxes, and conversations for each chat
# Avatar/nickname loaded lazily when user opens a conversation (not during sync)
class TiktokShop::LoadHistoryConversationService
  BATCH_SIZE = 20
  RATE_LIMIT_DELAY = 0.5 # seconds between API calls to respect rate limits

  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
    @new_conversation_ids = []
  end

  def perform
    return [] if @inbox.is_load_all_conversation?

    result = fetch_conversations
    return [] if result.blank?

    conversations_data = result.dig('data', 'conversations') || []
    save_conversations(conversations_data)
    save_paging_info(result.dig('data', 'next_page_token'))

    @new_conversation_ids
  rescue StandardError => e
    handle_error(e)
    []
  end

  private

  def client
    @client ||= @channel.client
  end

  def fetch_conversations
    params = { page_size: BATCH_SIZE }
    params[:page_token] = @inbox.next_cursor if @inbox.next_cursor.present?

    response = client.get_conversations(params)

    if response['code'] == Channel::TiktokShop::INVALID_ACCESS_TOKEN_CODE
      @channel.refresh_access_token
      response = client.get_conversations(params)
    end

    unless response['code']&.zero?
      Rails.logger.error("[TiktokShop::LoadHistoryConversationService] API error: #{response['code']} - #{response['message']}")
      return nil
    end

    response
  end

  def save_paging_info(next_page_token)
    is_all_loaded = next_page_token.blank?
    # rubocop:disable Rails/SkipsModelValidations
    @inbox.update_columns(next_cursor: next_page_token.presence, is_load_all_conversation: is_all_loaded)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def save_conversations(conversations_data)
    conversations_data.each do |conv_data|
      process_single_conversation(conv_data)
    rescue StandardError => e
      Rails.logger.error("[TiktokShop::LoadHistoryConversationService] Error processing conversation #{conv_data['conversation_id']}: #{e.message}")
    end
  end

  def process_single_conversation(conv_data)
    conversation_id = conv_data['conversation_id']
    return if conversation_id.blank?

    buyer = find_buyer(conv_data)
    return if buyer.blank?

    contact_inbox = find_or_create_contact(buyer)
    return if find_existing_conversation(contact_inbox, conversation_id)

    conversation = build_conversation(contact_inbox, conv_data)
    @new_conversation_ids << conversation.id
  end

  def find_buyer(conv_data)
    participants = conv_data['participants'] || []
    participants.find { |p| p['role'] == 'BUYER' } || participants.first
  end

  def find_or_create_contact(buyer)
    buyer_im_user_id = buyer['im_user_id']
    contact_attrs = {
      name: buyer['nickname'].presence || buyer_im_user_id
    }

    ContactInboxWithContactBuilder.new(
      source_id: buyer_im_user_id,
      inbox: @inbox,
      contact_attributes: contact_attrs
    ).perform
  end

  def find_existing_conversation(contact_inbox, conversation_id)
    contact_inbox.conversations.find_by(external_source_id: conversation_id) ||
      contact_inbox.conversations.find_by(
        inbox_id: @inbox.id,
        contact_id: contact_inbox.contact_id,
        contact_inbox_id: contact_inbox.id
      )
  end

  def build_conversation(contact_inbox, conv_data)
    activity_time = conv_data['create_time'] ? Time.zone.at(conv_data['create_time'].to_i) : Time.current

    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      external_source_id: conv_data['conversation_id'],
      last_activity_at: activity_time,
      agent_last_seen_at: DateTime.now.utc,
      loaded_from_history: true
    )
  end

  def handle_error(error)
    Rails.logger.error("[TiktokShop::LoadHistoryConversationService] #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end
end
