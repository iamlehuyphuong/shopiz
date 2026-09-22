class Captain::Copilot::ChatService < Llm::BaseAiService
  include Captain::ChatHelper
  include Captain::CreditGuard

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
    return { error: I18n.t('captain.copilot_limit'), error_code: 429 } unless responses_available?

    if using_user_hook_key_for_credit?
      Rails.logger.info(
        "[CAPTAIN][#{self.class.name}] Using user hook API key for account #{@account.id} (system credits exhausted)"
      )
    end

    @messages << { role: 'user', content: input } if input.present?
    response = request_chat_completion

    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }
    increment_usage_if_system_key!

    response
  end

  def chat(model: @model, temperature: @temperature)
    if using_user_hook_key_for_credit?
      Llm::Config.with_api_key(user_hook_api_key, api_base: user_hook_api_base) do |context|
        context.chat(model: model).with_temperature(temperature)
      end
    else
      super
    end
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

  BASE_TOOL_CLASSES = [
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
    Captain::Tools::ExecuteMacroService,
    Captain::Tools::Copilot::GetContactNotesService,
    Captain::Tools::Copilot::ListAutomationRulesService,
    Captain::Tools::Copilot::CreateScenarioService,
    Captain::Tools::Copilot::SendZaloFriendRequestService,
    Captain::Tools::Copilot::UpdateConversationTagsService
  ].freeze

  ECOM_TOOL_CLASSES = [
    Captain::Tools::Copilot::SearchOrdersService,
    Captain::Tools::Copilot::GetOrderDetailService,
    Captain::Tools::Copilot::CreateOrderService,
    Captain::Tools::Copilot::PushOrderService,
    Captain::Tools::Copilot::SearchCustomersService,
    Captain::Tools::Copilot::CreateCustomerService,
    Captain::Tools::Copilot::UpdateCustomerService,
    Captain::Tools::Copilot::SuggestProductsService,
    Captain::Tools::Copilot::CheckInventoryService,
    Captain::Tools::Copilot::SearchProductsService,
    Captain::Tools::Copilot::ConfirmOrderService,
    Captain::Tools::Copilot::UpdateOrderService
  ].freeze

  BOOKING_TOOL_CLASSES = [
    Captain::Tools::Copilot::ListEventTypesService,
    Captain::Tools::Copilot::GetAvailableTimesService,
    Captain::Tools::Copilot::BookAppointmentService,
    Captain::Tools::Copilot::GetScheduledEventsService,
    Captain::Tools::Copilot::ManageBookingService,
    Captain::Tools::Copilot::SearchMeetingsService,
    Captain::Tools::Copilot::GetBookingLinkService
  ].freeze

  def build_tools
    tools = base_copilot_tools
    tools += ecom_copilot_tools
    tools += booking_copilot_tools
    tools.select(&:active?)
  end

  def base_copilot_tools
    BASE_TOOL_CLASSES.map { |klass| klass.new(@assistant, user: @user, conversation: @conversation) }
  end

  def ecom_copilot_tools
    ECOM_TOOL_CLASSES.map { |klass| klass.new(@assistant, user: @user, conversation: @conversation) }
  end

  def booking_copilot_tools
    BOOKING_TOOL_CLASSES.map { |klass| klass.new(@assistant, user: @user, conversation: @conversation) }
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(
        @assistant.config,
        tools_summary,
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
