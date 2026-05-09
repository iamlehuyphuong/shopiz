class Captain::Llm::ContactAttributesService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  def initialize(assistant, conversation)
    super(account: assistant&.account)
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @content = "#Contact\n\n#{@contact.to_llm_text} \n\n#Conversation\n\n#{@conversation.to_llm_text}"
  end

  def generate_and_update_attributes
    attributes_array = generate_attributes
    return if attributes_array.blank?

    attributes_to_update = {}
    custom_attrs = @contact.custom_attributes || {}

    attributes_array.each do |feature|
      key = feature['attribute'].to_s
      val = feature['value']
      next if key.blank? || val.blank?

      case key
      when 'phone_number'
        # Chỉ cập nhật nếu đang trống
        attributes_to_update[:phone_number] = val if @contact.phone_number.blank?
      when 'email'
        attributes_to_update[:email] = val.downcase if @contact.email.blank?
      when 'identifier', 'cccd', 'cmnd'
        attributes_to_update[:identifier] = val if @contact.identifier.blank?
      when 'address'
        attributes_to_update[:location] = val if @contact.location.blank?
        custom_attrs[key] = val if custom_attrs[key].blank?
      else
        # Ghi các thông tin phụ vào custom_attributes nếu chưa có
        custom_attrs[key] = val if custom_attrs[key].blank?
      end
    end

    attributes_to_update[:custom_attributes] = custom_attrs
    @contact.update(attributes_to_update) if attributes_to_update.any?
  end

  private

  attr_reader :content

  def generate_attributes
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_params(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end
    parse_response(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    []
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.contact_attributes',
      model: @model,
      temperature: @temperature,
      account_id: @conversation.account_id,
      feature_name: 'contact_attributes',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { assistant_id: @assistant.id, contact_id: @contact.id }
    }
  end

  def system_prompt
    Captain::Llm::SystemPromptsService.attributes_generator
  end

  def parse_response(content)
    return [] if content.nil?

    JSON.parse(sanitize_json_response(content)).fetch('attributes', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
