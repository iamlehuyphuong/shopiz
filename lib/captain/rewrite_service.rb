class Captain::RewriteService < Captain::BaseTaskService
  pattr_initialize [:account!, :content!, :operation!, { conversation_display_id: nil, context: {} }]

  TONE_OPERATIONS = %i[casual professional friendly confident straightforward].freeze

  IMPROVE_OPERATIONS = %i[
    improve_summary_instruction
    improve_reporting_instruction
    improve_team_description
    improve_zalo_friend_request
    improve_zalo_greeting
    improve_auto_followup_message
    improve_auto_followup_instruction
    improve_label_description
    improve_custom_attribute_description
    improve_automation_rule_description
    improve_agent_bot_description
    improve_canned_response_message
    improve_sla_description
    improve_custom_role_description
    improve_campaign_message
  ].freeze

  ALLOWED_OPERATIONS = (%i[fix_spelling_grammar improve improve_assistant_description] + TONE_OPERATIONS + IMPROVE_OPERATIONS).freeze

  def perform
    operation_sym = operation.to_sym
    raise ArgumentError, "Invalid operation: #{operation}" unless ALLOWED_OPERATIONS.include?(operation_sym)

    send(operation_sym)
  end

  TONE_OPERATIONS.each do |tone|
    define_method(tone) do
      call_llm_with_prompt(tone_rewrite_prompt(tone.to_s))
    end
  end

  IMPROVE_OPERATIONS.each do |operation|
    define_method(operation) do
      call_llm_with_prompt(prompt_from_file(operation.to_s))
    end
  end

  private

  def improve_assistant_description
    template = prompt_from_file('improve_assistant_description')

    variables = {
      'assistant_name' => context['assistant_name'] || context[:assistant_name],
      'company_name' => context['company_name'] || context[:company_name],
      'industry' => context['industry'] || context[:industry],
      'core_products' => context['core_products'] || context[:core_products],
      'current_description' => content
    }

    system_prompt = render_liquid_template(template, variables)
    call_llm_with_prompt(system_prompt, content)
  end

  def fix_spelling_grammar
    call_llm_with_prompt(prompt_from_file('fix_spelling_grammar'))
  end

  def improve
    template = prompt_from_file('improve')

    system_prompt = render_liquid_template(template, {
                                             'conversation_context' => conversation.to_llm_text(include_contact_details: true),
                                             'draft_message' => content
                                           })

    call_llm_with_prompt(system_prompt, content)
  end

  def call_llm_with_prompt(system_content, user_content = content)
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_content },
        { role: 'user', content: user_content }
      ]
    )
  end

  def render_liquid_template(template_content, variables = {})
    Liquid::Template.parse(template_content).render(variables)
  end

  def tone_rewrite_prompt(tone)
    template = prompt_from_file('tone_rewrite')
    render_liquid_template(template, 'tone' => tone)
  end

  def event_name
    operation
  end
end
