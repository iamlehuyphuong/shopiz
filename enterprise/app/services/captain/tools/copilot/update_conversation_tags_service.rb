class Captain::Tools::Copilot::UpdateConversationTagsService < Captain::Tools::BaseTool
  def self.name
    'update_conversation_tags'
  end

  def self.description
    'Updates or adds tags (labels) to the current conversation to categorize it.'
  end

  def self.parameters
    {
      type: 'object',
      properties: {
        tags: {
          type: 'array',
          items: { type: 'string' },
          description: 'A list of tags/labels to add to the conversation.'
        }
      },
      required: ['tags']
    }
  end

  def execute(arguments)
    return { status: false, error: 'Conversation context is required.' } unless @conversation

    tags = arguments['tags']
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
