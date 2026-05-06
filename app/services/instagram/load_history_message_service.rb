class Instagram::LoadHistoryMessageService
  BASE_URI = 'https://graph.instagram.com'.freeze

  def initialize(conversation)
    @conversation = conversation
    @channel = @conversation.inbox.channel
    @new_messages = []
    @external_conversation_id = @conversation.external_source_id || fetch_conversation_id
  end

  def perform
    return if @external_conversation_id.blank? || @conversation.is_load_all_message

    result = fetch_messages
    return [] if result.blank?

    save_paging_info(result)
    process_messages(result['data'] || [])

    @new_messages
  rescue StandardError => e
    Rails.logger.error("[Instagram::LoadHistoryMessageService] #{e.message}")
    { messages: [], error: e.message }
  end

  private

  def process_messages(messages_data)
    messages_data.each do |message_data|
      next if message_already_exists?(message_data['id'])

      message = build_message(message_data)
      @new_messages << message.id if message
    end
  end

  def fetch_messages
    params = {
      fields: 'id,message,from,created_time,attachments{id,mime_type}',
      limit: 20,
      access_token: @channel.access_token
    }

    if @conversation.next_cursor.present?
      params[:after] = @conversation.next_cursor
    else
      oldest_message = @conversation.messages.order(:created_at).first
      params[:until] = oldest_message.created_at.to_i if oldest_message
    end

    url = "#{BASE_URI}/#{api_version}/#{@external_conversation_id}/messages"
    response = HTTParty.get(url, query: params)

    unless response.success?
      handle_error_response(response)
      return nil
    end

    JSON.parse(response.body)
  end

  def save_paging_info(result)
    next_cursor = result.dig('paging', 'cursors', 'after')
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns(next_cursor: next_cursor, is_load_all_message: next_cursor.blank?)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def message_already_exists?(source_id)
    return false if source_id.blank?

    Message.where(account_id: @conversation.account_id).exists?(source_id: source_id)
  end

  def build_message(message_data)
    from_id = message_data.dig('from', 'id')
    is_outgoing = from_id == @channel.instagram_id
    message_type = is_outgoing ? :outgoing : :incoming
    sender = is_outgoing ? nil : @conversation.contact

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: message_data['message'],
      source_id: message_data['id'],
      sender: sender,
      created_at: message_data['created_time'] ? Time.iso8601(message_data['created_time']) : Time.current
    )
  rescue StandardError => e
    Rails.logger.warn("[Instagram::LoadHistoryMessageService] Failed to build message #{message_data['id']}: #{e.message}")
    nil
  end

  def fetch_conversation_id
    source_id = @conversation.messages.order(created_at: :desc).pick(:source_id)
    return if source_id.blank?

    # Try to find the conversation ID from a message
    url = "#{BASE_URI}/#{api_version}/#{@channel.instagram_id}/conversations"
    params = {
      platform: 'instagram',
      user_id: @conversation.contact_inboxes.first&.source_id,
      access_token: @channel.access_token
    }

    response = HTTParty.get(url, query: params)
    return unless response.success?

    result = JSON.parse(response.body)
    source_conversation_id = result.dig('data', 0, 'id')
    update_source_conversation(source_conversation_id) if source_conversation_id

    source_conversation_id
  rescue StandardError => e
    Rails.logger.error("[Instagram::LoadHistoryMessageService] Error fetching conversation ID: #{e.message}")
    nil
  end

  def update_source_conversation(source_id)
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns external_source_id: source_id
    # rubocop:enable Rails/SkipsModelValidations
  end

  def handle_error_response(response)
    parsed = begin
      JSON.parse(response.body)
    rescue StandardError
      {}
    end
    error_code = parsed.dig('error', 'code')
    error_message = parsed.dig('error', 'message')

    @channel.authorization_error! if error_code == 190

    Rails.logger.error("[Instagram::LoadHistoryMessageService] API error #{error_code}: #{error_message}")
  end

  def api_version
    GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
  end
end
