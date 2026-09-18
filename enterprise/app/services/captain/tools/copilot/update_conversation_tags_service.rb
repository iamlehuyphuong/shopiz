class Captain::Tools::Copilot::UpdateConversationTagsService < Captain::Tools::BaseTool
  def self.name
    'update_conversation_tags'
  end

  description 'Updates or adds tags (labels) to the current conversation to categorize it.'

  param :tags, type: :array, desc: 'A list of tags/labels to add to the conversation.', required: true

  def execute(tags:)
    return { status: false, error: 'Conversation context is required.' } unless @conversation

    return { status: false, error: 'Tags array is required.' } unless tags.is_a?(Array)

    new_labels = (@conversation.label_list + tags).uniq
    @conversation.update_labels(new_labels)

    { status: true, message: 'Tags updated successfully.', current_tags: @conversation.label_list }
  rescue StandardError => e
    { status: false, error: e.message }
  end

  def active?
    true
  end
end
