class Facebook::LoadHistoryConversationService
  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
    @graph = Koala::Facebook::API.new(@channel.page_access_token)
    @new_conversation_ids = []
  end

  def perform
    return [] if @inbox.is_load_all_conversation?

    result = @graph.get_connections('me', 'conversations', load_more_params)

    save_conversations(result)
    save_paging_info(result.next_page_params&.dig(1, 'after'))

    @new_conversation_ids
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e
    @channel.authorization_error!
    []
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    []
  end

  private

  def load_more_params
    params = {
      limit: 20,
      fields: 'participants,updated_time,messages.limit(1){id,message,from,created_time,attachments,quick_reply}'
    }
    params[:after] = @inbox.next_cursor if @inbox.next_cursor.present?

    params
  end

  def save_paging_info(next_cursor)
    # rubocop:disable Rails/SkipsModelValidations
    @inbox.update_columns(next_cursor: next_cursor, is_load_all_conversation: next_cursor.blank?)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def save_conversations(result)
    result.each do |conversation_data|
      participants = conversation_data.dig('participants', 'data') || []
      source_conversation_id = conversation_data['id']
      sender = participants.find { |participant| participant['id'] != @channel.page_id }

      contact_inbox = @inbox.contact_inboxes.find_by(source_id: sender['id']) || build_contact_inbox(sender)

      if (exists_conversation = find_exist_conversation(contact_inbox))
        # rubocop:disable Rails/SkipsModelValidations
        exists_conversation.update_columns external_source_id: source_conversation_id
        # rubocop:enable Rails/SkipsModelValidations
        next
      end

      conversation = build_conversation(source_conversation_id, contact_inbox, conversation_data['updated_time'])
      message_data = conversation_data.dig('messages', 'data')&.first
      Facebook::MessageBuilder.new(conversation, @channel.page_id, message_data).perform
      @new_conversation_ids << conversation.id
    end
  end

  def build_contact_inbox(sender)
    ContactInboxWithContactBuilder.new({
                                         source_id: sender['id'],
                                         inbox: @inbox,
                                         contact_attributes: contact_params(sender)
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
    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      external_source_id: source_id,
      last_activity_at: Time.iso8601(last_activity_at),
      agent_last_seen_at: DateTime.now.utc,
      loaded_from_history: true
    )
  end

  def contact_params(sender)
    begin
      result = @graph.get_object(sender['id']) || {}
    rescue StandardError => e
      result = {}
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end

    process_contact_params_result(result)
  end

  def process_contact_params_result(result)
    {
      name: "#{result['first_name'] || 'John'} #{result['last_name'] || 'Doe'}",
      account_id: @inbox.account_id,
      avatar_url: result['profile_pic']
    }
  end
end
