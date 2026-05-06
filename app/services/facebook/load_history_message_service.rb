class Facebook::LoadHistoryMessageService
  def initialize(conversation)
    @conversation = conversation
    @channel = @conversation.inbox.channel
    @new_messages = []
    @graph = Koala::Facebook::API.new(@channel.page_access_token)
    @external_conversation_id = @conversation.external_source_id || fetch_conversation_id
  end

  def perform
    return if @external_conversation_id.blank? || @conversation.is_load_all_message

    result = @graph.get_connections(@external_conversation_id, 'messages', load_more_params)
    save_paging_info(result)

    result.each do |message_data|
      next if message_already_exists?(message_data['id'])

      message = Facebook::MessageBuilder.new(@conversation, @channel.page_id, message_data).perform
      @new_messages << message.id if message
    end
    @new_messages
  rescue Koala::Facebook::APIError => e
    Rails.logger.error("Facebook API Error: #{e.message}")
    { messages: [], error: e.message }
  end

  def load_more_params
    params = {
      limit: 20,
      fields: 'id,message,from,created_time,attachments{id, mime_type},is_echo'
    }
    if @conversation.next_cursor.present?
      params[:after] = @conversation.next_cursor
    else
      oldest_message = @conversation.messages.order(:created_at).first
      params[:until] = oldest_message.created_at.to_i if oldest_message
    end
    params
  end

  def message_already_exists?(source_id)
    return false if source_id.blank?

    Message.where(account_id: @conversation.account_id).exists?(source_id: source_id)
  end

  def save_paging_info(result)
    next_cursor = result.raw_response.dig('paging', 'cursors', 'after')
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns(next_cursor: next_cursor, is_load_all_message: next_cursor.blank?)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def fetch_conversation_id
    source_id = @conversation.messages.order(created_at: :desc).pick(:source_id)
    return if source_id.blank?

    result = @graph.get_object(source_id, fields: 'conversation')
    source_conversation_id = result.dig('conversation', 'id')
    update_source_conversation(source_conversation_id)

    source_conversation_id
  rescue Koala::Facebook::APIError => e
    Rails.logger.error("Facebook API error: #{e.message}")
    nil
  end

  def update_source_conversation(source_id)
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns external_source_id: source_id
    # rubocop:enable Rails/SkipsModelValidations
  end
end
