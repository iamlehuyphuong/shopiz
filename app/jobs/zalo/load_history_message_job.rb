# Loads message history for a specific Zalo OA conversation recursively
# Uses the get_conversation API with offset-based pagination
class Zalo::LoadHistoryMessageJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 10

  def perform(conversation_id, offset = 0) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    # Skip if we've already loaded everything
    return if conversation.is_load_all_message && offset.zero?

    channel = conversation.inbox.channel
    return unless channel.is_a?(Channel::ZaloOa)

    user_id = conversation.contact_inbox&.source_id
    return if user_id.blank?

    client = channel.client
    response = client.get_conversation(user_id, offset: offset, count: BATCH_SIZE)
    return unless response['error']&.zero?

    messages_data = response['data'] || []

    # Process messages
    process_messages(conversation, channel, messages_data)

    # Calculate pagination
    is_all_loaded = messages_data.size < BATCH_SIZE
    new_offset = offset + messages_data.size

    # Update cursor
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(next_cursor: new_offset.to_s, is_load_all_message: is_all_loaded)
    # rubocop:enable Rails/SkipsModelValidations

    # Recursively enqueue next batch if not done
    self.class.perform_later(conversation.id, new_offset) unless is_all_loaded
  rescue StandardError => e
    Rails.logger.error("[Zalo::LoadHistoryMessageJob] #{e.message}")
  end

  private

  def process_messages(conversation, channel, messages_data)
    messages_data.each do |message_data|
      source_id = message_data['message_id']
      next if source_id.blank?
      next if Message.where(account_id: conversation.account_id).exists?(source_id: source_id)

      build_message(conversation, channel, message_data)
    end
  end

  def build_message(conversation, channel, message_data)
    is_outgoing = message_data['from_id'] == channel.oa_id
    message_type = is_outgoing ? :outgoing : :incoming
    sender = is_outgoing ? nil : conversation.contact
    created_at = message_data['time'] ? Time.zone.at(message_data['time'].to_i / 1000) : Time.current

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      content: message_data['message'],
      source_id: message_data['message_id'],
      sender: sender,
      created_at: created_at
    )
  rescue StandardError => e
    Rails.logger.warn("[Zalo::LoadHistoryMessageJob] Failed to build message #{message_data['message_id']}: #{e.message}")
  end
end
