class Captain::Copilot::ChatService < Llm::BaseAiService
  include Captain::ChatHelper

  attr_reader :assistant, :account, :user, :copilot_thread, :previous_history, :messages

  def initialize(assistant, config)
    super(account: assistant.account)

    @assistant = assistant
    @account = assistant.account
    @user = nil
    @copilot_thread = nil
    @previous_history = []
    @conversation = @account.conversations.find_by(display_id: config[:conversation_id])
    @conversation_id = @conversation&.display_id

    setup_user(config)
    setup_message_history(config)
    @tools = build_tools
    @messages = build_messages(config)
  end

  def generate_response(input)
    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion

    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Incrementing response usage for account #{@account.id}"
    )
    @account.increment_response_usage

    response
  end

  private

  def setup_user(config)
    @user = @account.users.find_by(id: config[:user_id]) if config[:user_id].present?
  end

  def build_messages(config)
    messages= [system_message]
    messages << account_id_context
    messages += @previous_history if @previous_history.present?
    messages += current_viewing_history(config[:conversation_id]) if config[:conversation_id].present?
    messages
  end

  def setup_message_history(config)
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Previous History: #{config[:previous_history]&.length || 0}, Language: #{config[:language]}"
    )

    @copilot_thread = @account.copilot_threads.find_by(id: config[:copilot_thread_id]) if config[:copilot_thread_id].present?
    @previous_history = if @copilot_thread.present?
                          @copilot_thread.previous_history
                        else
                          config[:previous_history].presence || []
                        end
  end

  COPILOT_TOOL_CLASSES = [
    Captain::Tools::SearchDocumentationService,
    Captain::Tools::Copilot::GetConversationService,
    Captain::Tools::Copilot::SearchConversationsService,
    Captain::Tools::Copilot::GetArticleService,
    Captain::Tools::Copilot::SearchArticlesService,
    Captain::Tools::Copilot::GetContactService,
    Captain::Tools::Copilot::SearchContactsService,
    Captain::Tools::Copilot::SearchLinearIssuesService,
    Captain::Tools::Copilot::ListLabelsService,
    Captain::Tools::Copilot::ListTeamsService,
    Captain::Tools::Copilot::ListInboxesService,
    Captain::Tools::Copilot::SearchCannedResponsesService,
    Captain::Tools::Copilot::GetConversationSummaryService,
    Captain::Tools::Copilot::ListMacrosService,
    Captain::Tools::Copilot::GetContactNotesService,
    Captain::Tools::Copilot::ListAutomationRulesService,
    Captain::Tools::Copilot::SearchProductsService,
    Captain::Tools::Copilot::SuggestProductsService,
    Captain::Tools::Copilot::CheckInventoryService,
    Captain::Tools::Copilot::SearchOrdersService,
    Captain::Tools::Copilot::GetOrderDetailService,
    Captain::Tools::Copilot::CreateOrderService,
    Captain::Tools::Copilot::SearchCustomersService,
    Captain::Tools::Copilot::CreateCustomerService,
    Captain::Tools::Copilot::UpdateCustomerService,
    Captain::Tools::Copilot::PushOrderService,
    Captain::Tools::Copilot::CreateScenarioService,
    Captain::Tools::Copilot::CalendlyListEventTypesService,
    Captain::Tools::Copilot::CalendlyGetAvailableTimesService,
    Captain::Tools::Copilot::CalendlyBookAppointmentService,
    Captain::Tools::Copilot::CalendlyGetScheduledEventsService,
    Captain::Tools::Copilot::CalendlyManageBookingService
  ].freeze

  def build_tools
    COPILOT_TOOL_CLASSES.map { |klass| klass.new(@assistant, user: @user, conversation: @conversation) }.select(&:active?)
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(
        @assistant.config['product_name'],
        tools_summary,
        @assistant.config,
        orders: recent_orders
      )
    }
  end

  def tools_summary
    @tools.map { |tool| "- #{tool.class.name}: #{tool.class.description}" }.join("\n")
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

  def account_id_context
    {
      role: 'system',
      content: "The current account id is #{@account.id}. The account is using #{@account.locale_english_name} as the language."
    }
  end

  def current_viewing_history(conversation_id)
    conversation = @account.conversations.find_by(display_id: conversation_id)
    return [] unless conversation

    Rails.logger.info("#{self.class.name} Assistant: #{@assistant.id}, Setting viewing history for conversation_id=#{conversation_id}")
    contact_id = conversation.contact_id
    [{
      role: 'system',
      content: <<~HISTORY.strip
        You are currently viewing the conversation with the following details:
        Conversation ID: #{conversation_id}
        Contact ID: #{contact_id}
      HISTORY
    }]
  end

  def persist_message(message, message_type = 'assistant')
    return if @copilot_thread.blank?

    @copilot_thread.copilot_messages.create!(
      message: message,
      message_type: message_type
    )
  end

  def feature_name
    'copilot'
  end
end
