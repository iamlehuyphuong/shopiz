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

    trigger_contact_attributes(message, conversation)
    return unless conversation.inbox.auto_label_enabled?

    if conversation.inbox.captain_active?
      Captain::Llm::ConversationLabelingJob.set(wait: 15.minutes).perform_later(conversation.id, message.id)
    else
      incoming_count = conversation.messages.incoming.count
      if incoming_count > 0 && (incoming_count % 5).zero?
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

  def trigger_contact_attributes(message, conversation)
    return unless conversation.inbox.captain_active?
    return if message.content.blank?

    return unless contains_pii?(message.content)

    # Wait 10 seconds to allow for processing latest message in conversation context
    Captain::Llm::ContactAttributesJob.set(wait: 10.seconds).perform_later(conversation.id, message.id)
  end

  def contains_pii?(content)
    phone_regex = /(?:\+84|0)(?:[\s\-\.]?[0-9]){8,10}\b/
    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
    address_regex = /(?:xã|phường|tỉnh|thành phố|quận|huyện|toà nhà|khu phố|lô|ngõ|ngách|hẻm|đường|tổ|ấp|thôn|bản|khóm|x\.|p\.|t\.|tp\.|q\.|h\.|tp)[\s,:-]*[\p{L}0-9]+/i

    content.match?(phone_regex) || content.match?(email_regex) || content.match?(address_regex)
  end
end
