class Captain::Conversation::FollowupBuilderJob < ApplicationJob
  MAX_MESSAGE_LENGTH = 10_000
  retry_on ActiveStorage::FileNotFoundError, attempts: 3, wait: 2.seconds
  retry_on Faraday::BadRequestError, attempts: 3, wait: 2.seconds

  def perform(conversation, assistant, attempt_count = 0, base_message = nil)
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant
    @attempt_count = attempt_count
    @base_message = base_message

    # Do not execute if the conversation has been resolved
    return if @conversation.status == 'resolved'

    Current.executed_by = @assistant

    if captain_v2_enabled?
      generate_response_with_v2
    else
      generate_and_process_response
    end
  rescue ActiveStorage::FileNotFoundError, Faraday::BadRequestError => e
    handle_error(e)
    raise e
  rescue StandardError => e
    handle_error(e)
  ensure
    Current.executed_by = nil
  end

  private

  delegate :account, :inbox, to: :@conversation

  def generate_and_process_response
    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: collect_previous_messages,
      additional_message: followup_system_prompt,
      role: 'system'
    )
    process_response
  end

  def generate_response_with_v2
    history = collect_previous_messages
    # V2 AgentRunnerService doesn't explicitly accept 'additional_message' keyword parameter out of the box,
    # so we append the instruction at the end of the history.
    history << { role: 'user', content: followup_system_prompt }

    @response = Captain::Assistant::AgentRunnerService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: history
    )
    process_response
  end

  def process_response
    # Double check it is not resolved
    status = Conversation.uncached { Conversation.where(id: @conversation.id).pick(:status) }
    return if status == 'resolved' || status == Conversation.statuses[:resolved]

    # Re-check messaging window — AI generation may have taken time and the window could have expired
    unless Conversations::MessageWindowService.new(@conversation).can_reply?
      Rails.logger.info("[CAPTAIN][FollowupBuilderJob] Messaging window expired for #{@conversation.id}. Aborting.")
      return
    end

    if handoff_requested?
      process_action('handoff')
    else
      ActiveRecord::Base.transaction do
        create_messages
        Rails.logger.info("[CAPTAIN][FollowupBuilderJob] Incrementing response usage for #{account.id}")
        account.increment_response_usage
      end
    end
  end

  def collect_previous_messages
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .map do |message|
      message_hash = {
        content: prepare_multimodal_message_content(message),
        role: determine_role(message)
      }

      message_hash[:agent_name] = message.additional_attributes['agent_name'] if message.additional_attributes&.dig('agent_name').present?

      message_hash
    end
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end

  def handoff_requested?
    @response['response'] == 'conversation_handoff'
  end

  def process_action(action)
    case action
    when 'handoff'
      I18n.with_locale(@assistant.account.locale) do
        create_handoff_message
        @conversation.bot_handoff!
        send_out_of_office_message_if_applicable
      end
    end
  end

  def send_out_of_office_message_if_applicable
    return if @conversation.campaign.present?

    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(@conversation)
  end

  def create_handoff_message
    create_outgoing_message(
      @assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff')
    )
  end

  def create_messages
    validate_message_content!(@response['response'])
    create_outgoing_message(@response['response'], agent_name: @response['agent_name'])
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content, agent_name: nil)
    message_params = {
      account_id: account.id,
      inbox_id: inbox.id,
      message_type: 'outgoing',
      content: message_content,
      private: false,
      sender_type: 'AgentBot',
      sender_id: @assistant.id,
      content_attributes: { auto_follow_up_automated: true }
    }

    builder = Messages::MessageBuilder.new(nil, @conversation, message_params)
    message = builder.perform

    message.update!(additional_attributes: message.additional_attributes.merge('agent_name' => agent_name)) if agent_name.present?

    message
  end

  def handle_error(error)
    log_error(error)
    true
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end

  def captain_v2_enabled?
    account.feature_enabled?('captain_integration_v2')
  end

  def followup_system_prompt
    "System Instruction: The customer has not replied to our last message. " \
      "Here is the predefined follow-up message: '#{@base_message}'. " \
      'Please read the conversation context and rewrite this predefined message so it sounds natural, ' \
      'polite, and personalized to the customer\'s situation. ' \
      'Do not make any unauthorized promises or offer a handoff if it is not implied in the predefined message. ' \
      'Output ONLY the rewritten message content.'
  end
end
