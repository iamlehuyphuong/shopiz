class Instagram::LoadHistoryConversationService
  BASE_URI = 'https://graph.instagram.com'.freeze

  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
    @new_conversation_ids = []
  end

  def perform
    return [] if @inbox.is_load_all_conversation?

    result = fetch_conversations
    return [] if result.blank?

    save_conversations(result['data'] || [])
    save_paging_info(result.dig('paging', 'cursors', 'after'))

    @new_conversation_ids
  rescue StandardError => e
    handle_api_error(e)
    []
  end

  private

  def fetch_conversations
    params = {
      platform: 'instagram',
      limit: 20,
      fields: 'participants,updated_time,id,messages.limit(1){id,message,from,created_time}',
      access_token: @channel.access_token
    }
    params[:after] = @inbox.next_cursor if @inbox.next_cursor.present?

    url = "#{BASE_URI}/#{api_version}/#{@channel.instagram_id}/conversations"
    response = HTTParty.get(url, query: params)

    unless response.success?
      handle_error_response(response)
      return nil
    end

    JSON.parse(response.body)
  end

  def save_paging_info(next_cursor)
    # rubocop:disable Rails/SkipsModelValidations
    @inbox.update_columns(next_cursor: next_cursor, is_load_all_conversation: next_cursor.blank?)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def save_conversations(conversations_data)
    conversations_data.each do |conversation_data|
      process_single_conversation(conversation_data)
    end
  end

  def process_single_conversation(conversation_data)
    sender = find_sender_participant(conversation_data)
    return if sender.blank?

    source_conversation_id = conversation_data['id']
    contact_inbox = @inbox.contact_inboxes.find_by(source_id: sender['id']) || build_contact_inbox(sender)

    if (exists_conversation = find_exist_conversation(contact_inbox))
      # rubocop:disable Rails/SkipsModelValidations
      exists_conversation.update_columns external_source_id: source_conversation_id
      # rubocop:enable Rails/SkipsModelValidations
      return
    end

    conversation = build_conversation(source_conversation_id, contact_inbox, conversation_data['updated_time'])
    message_data = conversation_data.dig('messages', 'data')&.first
    build_message_from_data(conversation, message_data) if message_data
    @new_conversation_ids << conversation.id
  end

  def find_sender_participant(conversation_data)
    participants = conversation_data.dig('participants', 'data') || []
    participants.find { |participant| participant['id'] != @channel.instagram_id }
  end

  def build_contact_inbox(sender)
    contact_attrs = contact_params(sender)
    ContactInboxWithContactBuilder.new({
                                         source_id: sender['id'],
                                         inbox: @inbox,
                                         contact_attributes: contact_attrs
                                       }).perform
  end

  def find_exist_conversation(contact_inbox)
    contact_inbox.conversations.find_by(
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id
    )
  end

  def build_conversation(source_id, contact_inbox, last_activity_at)
    activity_time = last_activity_at ? Time.iso8601(last_activity_at) : Time.current
    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      external_source_id: source_id,
      last_activity_at: activity_time,
      agent_last_seen_at: DateTime.now.utc,
      loaded_from_history: true
    )
  end

  def contact_params(sender)
    user_info = fetch_instagram_user_profile(sender['id'])

    {
      name: user_info['name'] || user_info['username'] || 'Instagram User',
      account_id: @inbox.account_id,
      avatar_url: user_info['profile_pic']
    }
  end

  def fetch_instagram_user_profile(ig_scope_id)
    url = "#{BASE_URI}/#{api_version}/#{ig_scope_id}"
    params = {
      fields: 'name,username,profile_pic,follower_count,is_user_follow_business,is_business_follow_user',
      access_token: @channel.access_token
    }

    response = HTTParty.get(url, query: params)
    return {} unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.warn("[Instagram::LoadHistoryConversationService] Failed to fetch user profile for #{ig_scope_id}: #{e.message}")
    {}
  end

  def build_message_from_data(conversation, message_data)
    return if message_data.blank? || message_data['id'].blank?
    return if Message.where(account_id: conversation.account_id).exists?(source_id: message_data['id'])

    outgoing = outgoing_message?(message_data)

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: outgoing ? :outgoing : :incoming,
      content: message_data['message'],
      source_id: message_data['id'],
      sender: outgoing ? nil : conversation.contact,
      created_at: parse_message_time(message_data['created_time'])
    )
  rescue StandardError => e
    Rails.logger.warn("[Instagram::LoadHistoryConversationService] Failed to build message: #{e.message}")
  end

  def outgoing_message?(message_data)
    message_data.dig('from', 'id') == @channel.instagram_id
  end

  def parse_message_time(time_string)
    time_string ? Time.iso8601(time_string) : Time.current
  end

  def handle_error_response(response)
    parsed = begin
      JSON.parse(response.body)
    rescue StandardError
      {}
    end
    error_code = parsed.dig('error', 'code')
    error_message = parsed.dig('error', 'message')

    # Access token has expired or become invalid
    @channel.authorization_error! if error_code == 190

    Rails.logger.error("[Instagram::LoadHistoryConversationService] API error #{error_code}: #{error_message}")
  end

  def handle_api_error(error)
    Rails.logger.error("[Instagram::LoadHistoryConversationService] #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def api_version
    GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
  end
end
