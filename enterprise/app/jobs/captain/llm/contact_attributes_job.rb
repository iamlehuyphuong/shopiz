class Captain::Llm::ContactAttributesJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, message_id = nil)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation
    return unless conversation.inbox.captain_active?

    if message_id.present?
      # Ensure no new incoming messages have been created after this message_id
      last_incoming = conversation.messages.incoming.last
      return if last_incoming && last_incoming.id != message_id
    end

    assistant = conversation.inbox.captain_assistant
    Captain::Llm::ContactAttributesService.new(assistant, conversation).generate_and_update_attributes
  end
end
