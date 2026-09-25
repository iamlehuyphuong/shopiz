module Captain::ChatResponseHelper
  include Integrations::LlmInstrumentationConstants

  private

  def build_response(response)
    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }

    parsed = parse_json_response(response.content)

    persist_message(parsed, 'assistant')
    parsed
  end

  def parse_json_response(content)
    content = content.gsub('```json', '').gsub('```', '')
    content = content.strip
    parsed = JSON.parse(content)

    if parsed['scenario']
      parsed['content'] = parsed['scenario'].to_json
      parsed.delete('scenario')
    end

    parsed
  rescue JSON::ParserError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error parsing JSON response: #{e.message}"
    { 'content' => content }
  end

  def persist_thinking_message(tool_call)
    return if @copilot_thread.blank?

    tool_name = tool_call.name.to_s

    persist_message(
      {
        'content' => I18n.t('captain.copilot.using_tool', function_name: tool_name),
        'function_name' => tool_name
      },
      'assistant_thinking'
    )
  end

  def persist_tool_completion
    return if @copilot_thread.blank?

    tool_call = @pending_tool_calls&.pop
    return unless tool_call

    tool_name = tool_call.name.to_s

    persist_message(
      {
        'content' => I18n.t('captain.copilot.completed_tool_call', function_name: tool_name),
        'function_name' => tool_name
      },
      'assistant_thinking'
    )
  end
end
