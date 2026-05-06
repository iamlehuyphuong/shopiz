# Loads message history for a specific TikTok Shop conversation
# Uses the Customer Service API with cursor-based pagination (page_token)
# Creates message records for both incoming and outgoing messages
class TiktokShop::LoadHistoryMessageService
  BATCH_SIZE = 20

  def initialize(conversation)
    @conversation = conversation
    @channel = conversation.inbox.channel
    @new_message_ids = []
  end

  def perform
    return [] if @conversation.is_load_all_message

    result = fetch_messages
    return [] if result.blank?

    messages_data = result.dig('data', 'messages') || []
    save_paging_info(result.dig('data', 'next_page_token'))
    process_messages(messages_data)

    @new_message_ids
  rescue StandardError => e
    Rails.logger.error("[TiktokShop::LoadHistoryMessageService] #{e.message}")
    []
  end

  private

  def client
    @client ||= @channel.client
  end

  def conversation_id
    @conversation_id ||= @conversation.external_source_id
  end

  def fetch_messages
    return nil if conversation_id.blank?

    params = { page_size: BATCH_SIZE }
    params[:page_token] = @conversation.next_cursor if @conversation.next_cursor.present?

    response = client.get_messages(conversation_id, params)

    if response['code'] == Channel::TiktokShop::INVALID_ACCESS_TOKEN_CODE
      @channel.refresh_access_token
      response = client.get_messages(conversation_id, params)
    end

    unless response['code']&.zero?
      Rails.logger.error("[TiktokShop::LoadHistoryMessageService] API error: #{response['code']} - #{response['message']}")
      return nil
    end

    response
  end

  def save_paging_info(next_page_token)
    is_all_loaded = next_page_token.blank?
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns(next_cursor: next_page_token.presence, is_load_all_message: is_all_loaded)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def process_messages(messages_data)
    messages_data.each do |msg_data|
      next if message_already_exists?(msg_data['id'] || msg_data['message_id'])

      message = build_message(msg_data)
      @new_message_ids << message.id if message
    end
  end

  def message_already_exists?(source_id)
    return false if source_id.blank?

    Message.where(account_id: @conversation.account_id).exists?(source_id: source_id)
  end

  def build_message(msg_data)
    source_id = msg_data['id'] || msg_data['message_id']
    is_outgoing = outgoing_message?(msg_data)
    created_at = msg_data['create_time'] ? Time.zone.at(msg_data['create_time'].to_i) : Time.current

    message = @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: is_outgoing ? :outgoing : :incoming,
      content: extract_text_content(msg_data),
      source_id: source_id,
      sender: is_outgoing ? nil : @conversation.contact,
      created_at: created_at
    )

    attach_media(message, msg_data)
    message
  rescue StandardError => e
    Rails.logger.warn("[TiktokShop::LoadHistoryMessageService] Failed to build message #{msg_data['id']}: #{e.message}")
    nil
  end

  def outgoing_message?(msg_data)
    sender = msg_data['sender'] || {}
    sender['role'] == 'SHOP_OWNER' || sender['sender_type'] == 'SHOP'
  end

  def extract_text_content(msg_data)
    return nil unless msg_data['type'] == 'TEXT'

    content_json = msg_data['content']
    return content_json unless content_json.is_a?(String)

    parsed = JSON.parse(content_json)
    parsed['content']
  rescue JSON::ParserError
    content_json
  end

  def attach_media(message, msg_data)
    return unless %w[IMAGE VIDEO].include?(msg_data['type'])

    content_json = msg_data['content']
    content_data = content_json.is_a?(String) ? JSON.parse(content_json) : content_json
    url = content_data['url']
    return if url.blank?

    file_type = msg_data['type'] == 'IMAGE' ? :image : :video
    attachment_file = Down.download(url)
    message.attachments.create!(
      account_id: message.account_id,
      file_type: file_type,
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  rescue StandardError => e
    Rails.logger.warn("[TiktokShop::LoadHistoryMessageService] Failed to attach media: #{e.message}")
  end
end
