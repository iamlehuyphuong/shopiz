class Captain::Llm::ConversationLabelingJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, message_id = nil)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation
    return unless conversation.inbox.auto_label_enabled?

    if message_id.present?
      # Ensure no new incoming messages have been created after this message_id
      last_incoming = conversation.messages.incoming.last
      return if last_incoming && last_incoming.id != message_id
    end

    assistant = conversation.inbox.captain_assistant
    Captain::Llm::ConversationLabelingService.new(assistant, conversation).generate_and_update_labels
  end
end
