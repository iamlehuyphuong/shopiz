class Captain::Llm::AssistantChatService < Llm::BaseAiService
  include Captain::ChatHelper

  def initialize(assistant: nil, conversation: nil, source: nil)
    super(account: assistant&.account)

    @assistant = assistant
    @conversation = conversation
    @conversation_id = conversation&.display_id
    @source = source

    @messages = [system_message]
    @response = ''
    @tools = build_tools
  end

  # additional_message: A single message (String) from the user that should be appended to the chat.
  #                    It can be an empty String or nil when you only want to supply historical messages.
  # message_history:   An Array of already formatted messages that provide the previous context.
  # role:              The role for the additional_message (defaults to `user`).
  #
  # NOTE: Parameters are provided as keyword arguments to improve clarity and avoid relying on
  # positional ordering.
  def generate_response(additional_message: nil, message_history: [], role: 'user')
    @messages += message_history
    @messages << { role: role, content: additional_message } if additional_message.present?
    request_chat_completion
  end

  private

  def build_tools
    tools = [
      Captain::Tools::SearchDocumentationService.new(@assistant, user: nil),
      Captain::Tools::ExecuteMacroService.new(@assistant, user: nil, conversation: @conversation)
    ]

    if @assistant.account.hooks.exists?(app_id: 'calendly', status: :enabled)
      %w[
        calendly_list_event_types calendly_get_available_times
        calendly_book_appointment calendly_get_scheduled_events
        calendly_manage_booking
      ].each do |tool_id|
        tool_class = Captain::Assistant.resolve_tool_class(tool_id)
        tools << tool_class.new(@assistant) if tool_class
      end
    end

    tools
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(
        @assistant.name, @assistant.config,
        contact: contact_attributes,
        orders: recent_orders
      )
    }
  end

  def contact_attributes
    return nil unless @conversation&.contact
    return nil unless @assistant&.feature_contact_attributes

    @conversation.contact.attributes.symbolize_keys.slice(
      :id, :name, :email, :phone_number, :identifier, :custom_attributes
    )
  end

  def recent_orders
    return nil unless @conversation

    @conversation.conversation_orders.order(created_at: :desc).limit(5).map do |order|
      {
        id: order.id,
        external_order_id: order.external_order_id,
        external_source: order.external_source,
        status: order.status,
        total_amount: order.total_amount,
        currency: order.currency
      }
    end
  end

  def persist_message(message, message_type = 'assistant')
    # No need to implement
  end

  def feature_name
    'assistant'
  end
end
