class Captain::Tools::SetConversationCustomAttributeTool < Captain::Tools::BasePublicTool
  description 'Set or update custom attributes on a conversation for tracking metadata like issue type, order ID, sentiment, etc.'
  param :attributes, type: 'string', desc: 'JSON string of custom attributes to set (e.g. {"issue_type": "billing", "order_id": "ORD-123"})'

  def perform(tool_context, attributes:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation
    return 'Attributes are required' if attributes.blank?

    parsed_attributes = parse_attributes(attributes)
    return 'Invalid JSON format for attributes' unless parsed_attributes

    merged = (conversation.custom_attributes || {}).merge(parsed_attributes)
    conversation.update!(custom_attributes: merged)

    log_tool_usage('set_custom_attributes', { conversation_id: conversation.id, keys: parsed_attributes.keys })

    "Custom attributes updated for conversation ##{conversation.display_id}: #{parsed_attributes.keys.join(', ')}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update custom attributes: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def parse_attributes(attributes)
    parsed = attributes.is_a?(String) ? JSON.parse(attributes) : attributes
    parsed.is_a?(Hash) ? parsed : nil
  rescue JSON::ParserError
    nil
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
