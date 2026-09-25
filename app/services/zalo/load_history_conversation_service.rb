# Loads conversation history from Zalo OA using the list recent chats API
# Creates contacts, contact_inboxes, and conversations for each chat
# Uses offset-based pagination to iterate through all conversations
class Zalo::LoadHistoryConversationService
  BATCH_SIZE = 10

  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
    @new_conversation_ids = []
  end

  def perform
    return [] if @inbox.is_load_all_conversation?

    result = fetch_recent_chats
    return [] if result.blank?

    data = result['data'] || []
    save_conversations(data)
    save_paging_info(data.size)

    @new_conversation_ids
  rescue StandardError => e
    handle_error(e)
    []
  end

  private

  def client
    @client ||= @channel.client
  end

  def current_offset
    @inbox.next_cursor.to_i
  end

  def fetch_recent_chats
    response = client.list_recent_chats(offset: current_offset, count: BATCH_SIZE)

    unless response['error']&.zero?
      Rails.logger.error("[Zalo::LoadHistoryConversationService] API error: #{response['error']} - #{response['message']}")
      handle_token_error(response['error'])
      return nil
    end

    response
  end

  def save_paging_info(items_count)
    new_offset = current_offset + items_count
    is_all_loaded = items_count < BATCH_SIZE

    # rubocop:disable Rails/SkipsModelValidations
    @inbox.update_columns(next_cursor: new_offset.to_s, is_load_all_conversation: is_all_loaded)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def save_conversations(conversations_data)
    conversations_data.each do |conv_data|
      process_single_conversation(conv_data)
    rescue StandardError => e
      Rails.logger.error("[Zalo::LoadHistoryConversationService] Error processing conversation: #{e.message}")
    end
  end

  def process_single_conversation(conv_data)
    user_id = extract_user_id(conv_data)
    return if user_id.blank?

    contact_inbox = find_or_create_contact(user_id, conv_data)
    return if find_existing_conversation(contact_inbox)

    conversation = build_conversation(contact_inbox, conv_data)
    build_last_message(conversation, conv_data) if conv_data['message'].present?
    @new_conversation_ids << conversation.id
  end

  def extract_user_id(conv_data)
    # In listrecentchat response, from_id is the user who sent the last message
    # to_id is the recipient. We need the user (non-OA) ID.
    from_id = conv_data['from_id']
    to_id = conv_data['to_id']

    # The one that is NOT the OA is the user
    if from_id == @channel.oa_id
      to_id
    else
      from_id
    end
  end

  def find_or_create_contact(user_id, conv_data)
    contact_attrs = build_contact_attributes(user_id, conv_data)

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: user_id,
      inbox: @inbox,
      contact_attributes: contact_attrs
    ).perform

    # Fetch full profile if this is a new contact
    fetch_and_update_profile(contact_inbox.contact, user_id) if contact_inbox.contact.name == user_id

    contact_inbox
  end

  def build_contact_attributes(user_id, conv_data)
    # Use display name from conversation data if available
    name = if conv_data['from_id'] != @channel.oa_id && conv_data['from_display_name'].present?
             conv_data['from_display_name']
           elsif conv_data['to_id'] != @channel.oa_id && conv_data['to_display_name'].present?
             conv_data['to_display_name']
           else
             user_id
           end

    avatar_url = if conv_data['from_id'] == @channel.oa_id
                   conv_data['to_avatar']
                 else
                   conv_data['from_avatar']
                 end

    { name: name, avatar_url: avatar_url }.compact
  end

  def fetch_and_update_profile(contact, user_id)
    response = client.get_user_detail(user_id)
    return unless response['error']&.zero?

    data = response['data']
    contact.update!(name: data['display_name']) if data['display_name'].present?

    avatar_url = data.dig('avatars', '240') || data['avatar']
    ::Avatar::AvatarFromUrlJob.perform_later(contact, avatar_url) if avatar_url.present?
  rescue StandardError => e
    Rails.logger.warn("[Zalo::LoadHistoryConversationService] Failed to fetch profile for #{user_id}: #{e.message}")
  end

  def find_existing_conversation(contact_inbox)
    contact_inbox.conversations.find_by(
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id
    )
  end

  def build_conversation(contact_inbox, conv_data)
    activity_time = conv_data['time'] ? Time.at(conv_data['time'].to_i / 1000) : Time.current

    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      last_activity_at: activity_time,
      agent_last_seen_at: DateTime.now.utc,
      loaded_from_history: true
    )
  end

  def build_last_message(conversation, conv_data)
    return if conv_data['message_id'].blank?
    return if Message.where(account_id: conversation.account_id).exists?(source_id: conv_data['message_id'])

    is_outgoing = conv_data['from_id'] == @channel.oa_id

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: is_outgoing ? :outgoing : :incoming,
      content: conv_data['message'],
      source_id: conv_data['message_id'],
      sender: is_outgoing ? nil : conversation.contact,
      created_at: conv_data['time'] ? Time.at(conv_data['time'].to_i / 1000) : Time.current
    )
  rescue StandardError => e
    Rails.logger.warn("[Zalo::LoadHistoryConversationService] Failed to build message: #{e.message}")
  end

  def handle_token_error(error_code)
    @channel.prompt_reauthorization! if error_code == Zalo::Client::TOKEN_EXPIRED_ERROR
  end

  def handle_error(error)
    Rails.logger.error("[Zalo::LoadHistoryConversationService] #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end
end
