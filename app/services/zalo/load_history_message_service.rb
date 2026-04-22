# Loads message history for a specific Zalo OA conversation
# Uses the get_conversation API with offset-based pagination
# Creates message records for both incoming and outgoing messages
class Zalo::LoadHistoryMessageService
  BATCH_SIZE = 10

  def initialize(conversation)
    @conversation = conversation
    @channel = conversation.inbox.channel
    @new_message_ids = []
  end

  def perform
    return [] if @conversation.is_load_all_message

    user_id = find_user_id
    return [] if user_id.blank?

    result = fetch_messages(user_id)
    return [] if result.blank?

    data = result['data'] || []
    save_paging_info(data.size)
    process_messages(data)

    @new_message_ids
  rescue StandardError => e
    Rails.logger.error("[Zalo::LoadHistoryMessageService] #{e.message}")
    []
  end

  private

  def client
    @client ||= @channel.client
  end

  def current_offset
    @conversation.next_cursor.to_i
  end

  def find_user_id
    contact_inbox = @conversation.contact_inbox
    contact_inbox&.source_id
  end

  def fetch_messages(user_id)
    response = client.get_conversation(user_id, offset: current_offset, count: BATCH_SIZE)

    unless response['error']&.zero?
      Rails.logger.error("[Zalo::LoadHistoryMessageService] API error: #{response['error']} - #{response['message']}")
      return nil
    end

    response
  end

  def save_paging_info(items_count)
    new_offset = current_offset + items_count
    is_all_loaded = items_count < BATCH_SIZE

    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns(next_cursor: new_offset.to_s, is_load_all_message: is_all_loaded)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def process_messages(messages_data)
    messages_data.each do |message_data|
      next if message_already_exists?(message_data['message_id'])

      message = build_message(message_data)
      @new_message_ids << message.id if message
    end
  end

  def message_already_exists?(source_id)
    return false if source_id.blank?

    Message.where(account_id: @conversation.account_id).exists?(source_id: source_id)
  end

  def build_message(message_data)
    is_outgoing = message_data['from_id'] == @channel.oa_id
    message_type = is_outgoing ? :outgoing : :incoming
    sender = is_outgoing ? nil : @conversation.contact
    created_at = message_data['time'] ? Time.at(message_data['time'].to_i / 1000) : Time.current

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: message_data['message'],
      source_id: message_data['message_id'],
      sender: sender,
      created_at: created_at
    )
  rescue StandardError => e
    Rails.logger.warn("[Zalo::LoadHistoryMessageService] Failed to build message #{message_data['message_id']}: #{e.message}")
    nil
  end
end
