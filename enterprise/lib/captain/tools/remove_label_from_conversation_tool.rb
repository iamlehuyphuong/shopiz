class Captain::Tools::RemoveLabelFromConversationTool < Captain::Tools::BasePublicTool
  description 'Remove a label from a conversation'
  param :label_name, type: 'string', desc: 'The name of the label to remove'

  def perform(tool_context, label_name:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    label_name = label_name&.strip&.downcase
    return 'Label name is required' if label_name.blank?

    current_labels = conversation.label_list
    return "Label '#{label_name}' is not on this conversation" unless current_labels.map(&:downcase).include?(label_name)

    updated_labels = current_labels.reject { |l| l.downcase == label_name }
    conversation.update_labels(updated_labels)

    log_tool_usage('removed_label', conversation_id: conversation.id, label: label_name)

    "Label '#{label_name}' removed from conversation ##{conversation.display_id}"
  end

  private

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
