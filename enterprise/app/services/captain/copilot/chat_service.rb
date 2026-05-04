class Captain::Copilot::ChatService < Llm::BaseAiService
  include Captain::ChatHelper

  attr_reader :assistant, :account, :user, :copilot_thread, :previous_history, :messages

  def initialize(assistant, config)
    super()

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
    Captain::Tools::Copilot::ShopifySearchOrdersService,
    Captain::Tools::Copilot::ShopifySearchProductsService,
    Captain::Tools::Copilot::ShopifySearchCustomersService,
    Captain::Tools::Copilot::ShopifyCreateOrderService,
    Captain::Tools::Copilot::ShopifySuggestProductsService,
    Captain::Tools::Copilot::ShopifyCreateCustomerService,
    Captain::Tools::Copilot::ShopifyUpdateCustomerService,
    Captain::Tools::Copilot::ShopifyGetOrderDetailService,
    Captain::Tools::Copilot::ShopifyPushOrderService,
    Captain::Tools::Copilot::ShopifyCheckInventoryService,
    Captain::Tools::Copilot::KiotvietSearchOrdersService,
    Captain::Tools::Copilot::KiotvietSearchProductsService,
    Captain::Tools::Copilot::KiotvietSearchCustomersService,
    Captain::Tools::Copilot::KiotvietCreateOrderService,
    Captain::Tools::Copilot::KiotvietSuggestProductsService,
    Captain::Tools::Copilot::KiotvietCreateCustomerService,
    Captain::Tools::Copilot::KiotvietUpdateCustomerService,
    Captain::Tools::Copilot::KiotvietGetOrderDetailService,
    Captain::Tools::Copilot::KiotvietPushOrderService,
    Captain::Tools::Copilot::KiotvietCheckInventoryService,
    Captain::Tools::Copilot::HaravanSearchOrdersService,
    Captain::Tools::Copilot::HaravanSearchProductsService,
    Captain::Tools::Copilot::HaravanSearchCustomersService,
    Captain::Tools::Copilot::HaravanCreateOrderService,
    Captain::Tools::Copilot::HaravanSuggestProductsService,
    Captain::Tools::Copilot::HaravanCreateCustomerService,
    Captain::Tools::Copilot::HaravanUpdateCustomerService,
    Captain::Tools::Copilot::HaravanGetOrderDetailService,
    Captain::Tools::Copilot::HaravanPushOrderService,
    Captain::Tools::Copilot::HaravanCheckInventoryService,
    Captain::Tools::Copilot::WoocommerceSearchOrdersService,
    Captain::Tools::Copilot::WoocommerceSearchProductsService,
    Captain::Tools::Copilot::WoocommerceSearchCustomersService,
    Captain::Tools::Copilot::WoocommerceCreateOrderService,
    Captain::Tools::Copilot::WoocommerceSuggestProductsService,
    Captain::Tools::Copilot::WoocommerceCreateCustomerService,
    Captain::Tools::Copilot::WoocommerceUpdateCustomerService,
    Captain::Tools::Copilot::WoocommerceGetOrderDetailService,
    Captain::Tools::Copilot::WoocommercePushOrderService,
    Captain::Tools::Copilot::WoocommerceCheckInventoryService,
    Captain::Tools::Copilot::SapoSearchOrdersService,
    Captain::Tools::Copilot::SapoSearchProductsService,
    Captain::Tools::Copilot::SapoSearchCustomersService,
    Captain::Tools::Copilot::SapoCreateOrderService,
    Captain::Tools::Copilot::SapoSuggestProductsService,
    Captain::Tools::Copilot::SapoCreateCustomerService,
    Captain::Tools::Copilot::SapoUpdateCustomerService,
    Captain::Tools::Copilot::SapoGetOrderDetailService,
    Captain::Tools::Copilot::SapoPushOrderService,
    Captain::Tools::Copilot::SapoCheckInventoryService,
    Captain::Tools::Copilot::NhanhvnSearchOrdersService,
    Captain::Tools::Copilot::NhanhvnSearchProductsService,
    Captain::Tools::Copilot::NhanhvnSearchCustomersService,
    Captain::Tools::Copilot::NhanhvnCreateOrderService,
    Captain::Tools::Copilot::NhanhvnSuggestProductsService,
    Captain::Tools::Copilot::NhanhvnCreateCustomerService,
    Captain::Tools::Copilot::NhanhvnUpdateCustomerService,
    Captain::Tools::Copilot::NhanhvnGetOrderDetailService,
    Captain::Tools::Copilot::NhanhvnPushOrderService,
    Captain::Tools::Copilot::NhanhvnCheckInventoryService,
    Captain::Tools::Copilot::TiktokShopSearchProductsService,
    Captain::Tools::Copilot::TiktokShopSuggestProductsService,
    Captain::Tools::Copilot::TiktokShopCheckInventoryService,
    Captain::Tools::Copilot::TiktokShopSearchOrdersService,
    Captain::Tools::Copilot::TiktokShopGetOrderDetailService,
    Captain::Tools::Copilot::CreateScenarioService
  ].freeze

  def build_tools
    COPILOT_TOOL_CLASSES.map { |klass| klass.new(@assistant, user: @user) }.select(&:active?)
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.copilot_response_generator(
        @assistant.config['product_name'],
        tools_summary,
        @assistant.config
      )
    }
  end

  def tools_summary
    @tools.map { |tool| "- #{tool.class.name}: #{tool.class.description}" }.join("\n")
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
