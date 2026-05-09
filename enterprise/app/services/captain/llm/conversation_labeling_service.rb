class Captain::Llm::ConversationLabelingService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(assistant, conversation)
    super(account: assistant&.account || conversation.account)
    @assistant = assistant
    @conversation = conversation
    @account = conversation.account
    @labels = @account.labels
    @content = "#Conversation\n\n#{@conversation.to_llm_text}"
  end

  def generate_and_update_labels
    return if @labels.empty?

    result = generate_labels
    return if result.empty?

    add_labels = extract_valid_labels(result['add_labels'])
    remove_labels = extract_valid_labels(result['remove_labels'])

    ActiveRecord::Base.transaction do
      @conversation.label_list.add(add_labels) if add_labels.present?
      @conversation.label_list.remove(remove_labels) if remove_labels.present?
      @conversation.save!
    end
  end

  private

  def extract_valid_labels(labels_from_llm)
    return [] unless labels_from_llm.is_a?(Array)

    valid_titles = @labels.pluck(:title)
    labels_from_llm.select { |title| valid_titles.include?(title) }
  end

  attr_reader :content

  def generate_labels
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end
    parse_response(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    {}
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.conversation_labeling',
      model: @model,
      temperature: @temperature,
      account_id: @account.id,
      conversation_id: @conversation.display_id,
      feature_name: 'conversation_labeling',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { assistant_id: @assistant&.id }
    }
  end

  def system_prompt
    account_language = @account.locale_english_name
    Captain::Llm::SystemPromptsService.label_generator(@labels, account_language)
  end

  def parse_response(response)
    return {} if response.nil?

    JSON.parse(sanitize_json_response(response))
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    {}
  end
end
