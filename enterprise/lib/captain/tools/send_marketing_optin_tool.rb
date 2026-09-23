class Captain::Tools::SendMarketingOptinTool < Captain::Tools::BasePublicTool
  description 'Send a Meta Marketing Messages Opt-in request to the customer on Facebook Messenger. This asks the customer for permission to receive promotional messages outside the standard 24-hour messaging window. Send this when they agree or show interest in receiving future updates or promotions.'

  param :title, type: 'string',
                desc: 'The question or statement displayed in the opt-in request. For example: "Would you like to receive exclusive offers and promotions from us?"'
  param :topic, type: 'string', desc: 'The internal topic identifier (e.g., marketing, events, news). Default is marketing.', required: false

  def perform(tool_context, title:, topic: 'marketing')
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'This tool can only be used on Facebook Page conversations' unless conversation.inbox.facebook?

    # Avoid redundant requests
    if ContactOptin.exists?(contact_id: conversation.contact_id, inbox_id: conversation.inbox_id, status: :active)
      return 'Customer has already opted in for marketing messages from this inbox'
    end

    ActiveRecord::Base.transaction do
      message = conversation.messages.create!(
        message_type: :outgoing,
        private: false,
        sender: @assistant,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: title,
        content_type: 'marketing_optin',
        content_attributes: { topic: topic }
      )

      log_tool_usage('send_marketing_optin', {
                       conversation_id: conversation.id,
                       topic: topic,
                       message_id: message.id
                     })
    end

    'Marketing opt-in request successfully sent to the customer.'
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to send marketing opt-in request due to an error.'
  end

  private

  def permissions
    %w[conversation_manage]
  end
end
