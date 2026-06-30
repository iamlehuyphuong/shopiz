class CaptainListener < BaseListener
  include ::Events::Types

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate if assistant.config['feature_faq'].present?
  end

  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    return unless conversation.inbox.auto_label_enabled?

    return unless conversation.inbox.captain_active? && %w[open resolved].include?(conversation.status)

    Captain::Llm::ConversationLabelingJob.perform_later(conversation.id)
  end

  def message_created(event)
    message, conversation = extract_message_and_conversation(event)
    return unless message.incoming?

    return unless conversation.inbox.auto_label_enabled?

    if conversation.inbox.captain_active?
      Captain::Llm::ConversationLabelingJob.set(wait: 15.minutes).perform_later(conversation.id, message.id)
    else
      incoming_count = conversation.messages.incoming.count
      if incoming_count.positive? && (incoming_count % 5).zero?
        Captain::Llm::ConversationLabelingJob.perform_later(conversation.id)
      else
        Captain::Llm::ConversationLabelingJob.set(wait: 15.minutes).perform_later(conversation.id, message.id)
      end
    end
  end

  private

  def extract_message_and_conversation(event)
    message = event.data[:message]
    [message, message.conversation]
  end
end
