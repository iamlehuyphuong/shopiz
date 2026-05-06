class Captain::Tools::AddInteractiveMessageToConversationTool < Captain::Tools::BasePublicTool
  description 'Add a interactive message to a conversation'
  param :message, type: 'string', desc: 'The message content'
  param :content_type, type: 'string', desc: 'The message content type'
  param :content_attributes, type: 'string', desc: 'The content attributes'

  def perform(tool_context, message: 'Demo', content_type: 'input_select', content_attributes: '{}')
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'Message content is required' if message.blank?

    log_tool_usage('add_interactive_message', { conversation_id: conversation.id, message_length: message.length })
    create_interactive_message(conversation, message, content_type, content_attributes)

    'Interactive message added successfully'
  rescue JSON::ParserError
    'Invalid JSON format for content_attributes'
  end

  private

  def create_interactive_message(conversation, message, content_type, content_attributes)
    parsed_attributes = content_attributes.is_a?(String) ? JSON.parse(content_attributes.encode('UTF-8')) : content_attributes
    conversation.messages.create!(
      account: @assistant.account,
      inbox: conversation.inbox,
      sender: @assistant,
      message_type: :template,
      content: message,
      content_type: content_type,
      content_attributes: parsed_attributes,
      private: false
    )
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
