class Captain::Tools::SearchPreviousConversationTool < Captain::Tools::BasePublicTool
  description 'Search previous conversations of the current contact to understand their history and context'
  param :status, type: 'string', desc: 'Filter by status: open, resolved, pending, snoozed. Leave empty for all.', required: false
  param :limit, type: 'string', desc: 'Maximum number of conversations to return (default: 5, max: 10)', required: false

  def perform(tool_context, status: nil, limit: '5')
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    current_conversation_id = tool_context.state&.dig(:conversation, :id)
    conversations = fetch_conversations(contact, current_conversation_id, status, limit)

    log_tool_usage('search_previous_conversations', { contact_id: contact.id, count: conversations.size })

    return "No previous conversations found for contact '#{contact.name}'" if conversations.empty?

    format_conversations(conversations, contact)
  end

  private

  def fetch_conversations(contact, current_conversation_id, status, limit)
    max_limit = [[limit.to_i, 1].max, 10].min
    scope = contact.conversations.where(account_id: @assistant.account_id)
    scope = scope.where.not(id: current_conversation_id) if current_conversation_id
    scope = scope.where(status: status) if status.present? && Conversation.statuses.key?(status)
    scope.order(created_at: :desc).limit(max_limit)
  end

  def format_conversations(conversations, contact)
    header = "Previous conversations for '#{contact.name}' (#{conversations.size} found):\n\n"

    body = conversations.map do |conv|
      last_message = conv.messages.where.not(message_type: :activity).order(created_at: :desc).first
      labels = conv.cached_label_list_array

      lines = []
      lines << "Conversation ##{conv.display_id} | Status: #{conv.status} | Created: #{conv.created_at.strftime('%Y-%m-%d')}"
      lines << "  Priority: #{conv.priority || 'none'}"
      lines << "  Labels: #{labels.join(', ')}" if labels.any?
      lines << "  Custom attrs: #{conv.custom_attributes.map { |k, v| "#{k}: #{v}" }.join(', ')}" if conv.custom_attributes&.any?
      lines << "  Last message: #{last_message.content&.truncate(200)}" if last_message&.content.present?
      lines.join("\n")
    end.join("\n---\n")

    header + body
  end
end
