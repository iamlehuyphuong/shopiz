require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::AgentRunnerService
  include Integrations::LlmInstrumentationConstants
  include Captain::Assistant::RunnerCallbacksHelper
  include Captain::Assistant::TracePayloadHelper
  include Captain::CreditGuard
  include Captain::UserHookKeyHelper

  attr_reader :account

  CONVERSATION_STATE_ATTRIBUTES = %i[
    id display_id inbox_id contact_id status priority
    label_list custom_attributes additional_attributes
  ].freeze

  CONTACT_STATE_ATTRIBUTES = %i[
    id name email phone_number identifier contact_type
    custom_attributes additional_attributes
  ].freeze

  CONTACT_INBOX_STATE_ATTRIBUTES = %i[id hmac_verified].freeze

  CAMPAIGN_STATE_ATTRIBUTES = %i[id title message campaign_type description].freeze
  def initialize(assistant:, conversation: nil, callbacks: {}, source: nil)
    @assistant = assistant
    @conversation = conversation
    @callbacks = callbacks
    @source = source
    @account = @assistant.account

    Llm::Config.initialize!
  end

  def generate_response(message_history: [])
    return error_response(I18n.t('captain.copilot_limit')) unless responses_available?

    message_to_process, context = run_payload(message_history)
    result = if using_user_hook_key_for_credit?
               resolved_api_base = user_hook_api_base.present? ? "#{user_hook_api_base}/v1" : nil
               Llm::Config.with_api_key(user_hook_api_key, api_base: resolved_api_base) do
                 summarize_history_if_needed(context)
                 runner.run(message_to_process, context: context, max_turns: 100)
               end
             else
               summarize_history_if_needed(context)
               runner.run(message_to_process, context: context, max_turns: 100)
             end

    process_agent_result(result)
  rescue StandardError => e
    # In rake/local runs, conversation may not be present, so account is optional here.
    ChatwootExceptionTracker.new(e, account: @conversation&.account).capture_exception
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    error_response(e.message)
  end

  private

  def build_context_with_summary(message_history)
    summary = format_history_summary(message_history)

    {
      session_id: "#{@assistant.account_id}_#{@conversation&.display_id}",
      conversation_history: [],
      history_summary: summary,
      state: build_state
    }
  end

  def summarize_history_if_needed(context)
    text_to_summarize = context[:history_summary]
    return if text_to_summarize.blank?

    prompt = <<~PROMPT
      You are an AI assistant. Below is the older portion of a conversation between a customer and an assistant.
      Summarize the key information, issues, and decisions from this conversation in a concise manner.
      Ensure you retain any important context, product names, order IDs, or specific requirements mentioned by the customer.

      Conversation:
      #{text_to_summarize}
    PROMPT

    chat = RubyLLM::Chat.new(context: Llm::Config.current_context)
    chat.ask(prompt)
    context[:history_summary] = chat.messages.last.content
  rescue StandardError => e
    Rails.logger.error "[Captain V2] Auto-summarization failed: #{e.message}"
    # Keep the un-summarized text if LLM call fails
  end

  def build_context_with_structured_history(recent_history, older_messages)
    summary = format_history_summary(older_messages) if older_messages.any?

    conversation_history = recent_history.map do |msg|
      content = msg[:content]
      content = extract_text_from_content(content) unless content.is_a?(Array)

      {
        role: msg[:role].to_sym,
        content: content,
        agent_name: msg[:agent_name]
      }.compact
    end

    {
      session_id: "#{@assistant.account_id}_#{@conversation&.display_id}",
      conversation_history: conversation_history,
      history_summary: summary,
      state: build_state
    }
  end

  def format_history_summary(messages)
    return nil if messages.blank?

    lines = [
      '## Conversation History',
      'Below is the recent conversation between the customer and the assistant.',
      'IMPORTANT: If the customer refers to a product, service, or information already mentioned below, use that information directly. Do NOT call search tools again for information already available here.',
      ''
    ]

    messages.each do |msg|
      content = msg[:content]
      content = extract_text_from_content(content) unless content.is_a?(String)
      next if content.blank?

      label = msg[:role] == 'user' ? '[Customer]' : '[Assistant]'
      lines << "#{label}: #{content}"
    end

    lines.join("\n")
  end

  def build_context(message_history)
    conversation_history = message_history.map do |msg|
      content = msg[:content]
      # Preserve multimodal arrays (with image_url entries) as-is for the runner to restore with attachments.
      # Only extract text from non-array formats (hashes from agent structured output, plain strings).
      content = extract_text_from_content(content) unless content.is_a?(Array)

      {
        role: msg[:role].to_sym,
        content: content,
        agent_name: msg[:agent_name]
      }
    end

    {
      session_id: "#{@assistant.account_id}_#{@conversation&.display_id}",
      conversation_history: conversation_history,
      state: build_state
    }
  end

  def extract_last_user_message(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }
    return '' if last_user_msg.blank?

    content = last_user_msg[:content]
    return extract_text_from_content(content) unless content.is_a?(Array)

    text, attachments = Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content)
    return text if attachments.blank?

    RubyLLM::Content.new(text, attachments)
  end

  def message_history_without_last_user_message(message_history)
    last_user_index = message_history.rindex { |msg| msg[:role] == 'user' }
    return message_history if last_user_index.nil?

    message_history.reject.with_index { |_msg, index| index == last_user_index }
  end

  def extract_text_from_content(content)
    # Handle structured output from agents
    return content[:response] || content['response'] || content.to_s if content.is_a?(Hash)

    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  def process_agent_result(result)
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"
    return error_response(result.error.message) if result.error.present?

    output = result.output
    response = output.is_a?(Hash) ? output.with_indifferent_access : { 'response' => output.to_s, 'reasoning' => 'Processed by agent' }
    response['agent_name'] = result.context&.dig(:current_agent)

    response['tool_execution_trace'] = result.context[:tool_execution_trace] if @source == 'playground' && result.context&.key?(:tool_execution_trace)

    response
  end

  def error_response(error_message)
    {
      'response' => 'conversation_handoff',
      'reasoning' => "Error occurred: #{error_message}"
    }
  end

  def build_state
    state = {
      account_id: @assistant.account_id,
      assistant_id: @assistant.id,
      assistant_config: @assistant.config
    }
    state[:source] = @source if @source.present?

    build_conversation_state(state) if @conversation
    state
  end

  def build_conversation_state(state)
    state[:conversation] = slice_attrs(@conversation, CONVERSATION_STATE_ATTRIBUTES)
    state[:channel_type] = @conversation.inbox&.channel_type
    state[:contact] = slice_attrs(@conversation.contact, CONTACT_STATE_ATTRIBUTES) if @conversation.contact
    state[:campaign] = slice_attrs(@conversation.campaign, CAMPAIGN_STATE_ATTRIBUTES) if @conversation.campaign
    state[:contact_inbox] = slice_attrs(@conversation.contact_inbox, CONTACT_INBOX_STATE_ATTRIBUTES) if @conversation.contact_inbox
    state[:recent_orders] = recent_orders
  end

  def recent_orders
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

  def slice_attrs(record, keys)
    record.attributes.symbolize_keys.slice(*keys)
  end

  def build_and_wire_agents
    assistant_agent = @assistant.agent
    scenario_agents = @assistant.scenarios.enabled.map(&:agent)

    assistant_agent.register_handoffs(*scenario_agents) if scenario_agents.any?
    scenario_agents.each { |scenario_agent| scenario_agent.register_handoffs(assistant_agent) }

    [assistant_agent] + scenario_agents
  end

  def install_instrumentation(runner)
    return unless ChatwootApp.otel_enabled?

    Agents::Instrumentation.install(
      runner,
      tracer: OpentelemetryConfig.tracer,
      trace_name: 'llm.captain',
      span_attributes: {
        ATTR_LANGFUSE_TAGS => ['captain'].to_json
      },
      attribute_provider: ->(context_wrapper) { dynamic_trace_attributes(context_wrapper) }
    )
    register_trace_input_callback(runner)
  end

  def dynamic_trace_attributes(context_wrapper)
    state = context_wrapper&.context&.dig(:state) || {}
    conversation = state[:conversation] || {}
    trace_input = context_wrapper&.context&.dig(:captain_trace_input)

    {
      ATTR_LANGFUSE_USER_ID => state[:account_id],
      format(ATTR_LANGFUSE_METADATA, 'assistant_id') => state[:assistant_id],
      format(ATTR_LANGFUSE_METADATA, 'conversation_id') => conversation[:id],
      format(ATTR_LANGFUSE_METADATA, 'conversation_display_id') => conversation[:display_id],
      format(ATTR_LANGFUSE_METADATA, 'channel_type') => state[:channel_type],
      format(ATTR_LANGFUSE_METADATA, 'source') => state[:source],
      ATTR_LANGFUSE_TRACE_INPUT => trace_input,
      ATTR_LANGFUSE_OBSERVATION_INPUT => trace_input
    }.compact.transform_values(&:to_s)
  end

  def add_usage_metadata_callback(runner)
    handoff_tool_name = Captain::Tools::HandoffTool.new(@assistant).name

    runner.on_tool_start do |tool_name, args, context_wrapper|
      if @source == 'playground'
        context_wrapper.context[:tool_execution_trace_args] ||= {}
        # We might have multiple calls to the same tool, but a simple hash is fine for playground debugging
        context_wrapper.context[:tool_execution_trace_args][tool_name] = args
      end
    end

    runner.on_tool_complete do |tool_name, tool_result, context_wrapper|
      if @source == 'playground'
        context_wrapper.context[:tool_execution_trace] ||= []
        args = context_wrapper.context.dig(:tool_execution_trace_args, tool_name)

        # Chuyển đổi tool_result sang dạng chuỗi/hash an toàn để tránh vòng lặp đệ quy khi json encode
        safe_result = tool_result.is_a?(String) ? tool_result : tool_result.to_s
        context_wrapper.context[:tool_execution_trace] << { name: tool_name, args: args, result: safe_result }
      end

      track_handoff_usage(tool_name, handoff_tool_name, context_wrapper) if ChatwootApp.otel_enabled?
    end

    runner.on_run_complete do |_agent_name, _result, context_wrapper|
      write_credits_used_metadata(context_wrapper) if ChatwootApp.otel_enabled?
    end
    runner
  end

  def track_handoff_usage(tool_name, handoff_tool_name, context_wrapper)
    return unless context_wrapper&.context
    return unless tool_name.to_s == handoff_tool_name

    context_wrapper.context[:captain_handoff_tool_called] = true
  end

  def write_credits_used_metadata(context_wrapper)
    root_span = context_wrapper&.context&.dig(:__otel_tracing, :root_span)
    return unless root_span

    credit_used = !context_wrapper.context[:captain_handoff_tool_called]
    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'credit_used'), credit_used.to_s)
  end

  def runner
    @runner ||= begin
      configured_runner = Agents::Runner.with_agents(*build_and_wire_agents)
      configured_runner = add_usage_metadata_callback(configured_runner)
      configured_runner = add_callbacks_to_runner(configured_runner) if @callbacks.any?
      install_instrumentation(configured_runner)
      configured_runner
    end
  end

  def run_payload(message_history)
    limit = @assistant.history_limit_in_messages
    recent_messages = message_history.last(limit)
    older_messages = message_history.length > limit ? message_history[0...-limit] : []

    message_to_process = extract_last_user_message(recent_messages)
    history_without_last = message_history_without_last_user_message(recent_messages)
    context = build_context_with_structured_history(history_without_last, older_messages)
    enrich_context_with_trace_payload!(context, recent_messages, message_to_process)
    [message_to_process, context]
  end
end
