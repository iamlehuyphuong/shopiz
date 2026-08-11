# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# New features should inherit from this class.
class Llm::BaseAiService
  include Captain::UserHookKeyHelper

  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0

  attr_reader :model, :temperature

  def initialize(account: nil)
    Llm::Config.initialize!
    @account = account
    setup_model
    setup_temperature
  end

  def chat(model: @model, temperature: @temperature)
    if system_api_key_available?
      RubyLLM.chat(model: model).with_temperature(temperature)
    elsif @account && user_hook_key_allowed? && user_hook_api_key.present?
      api_base = user_hook_api_base
      Llm::Config.with_api_key(user_hook_api_key, api_base: api_base) do |context|
        return context.chat(model: model).with_temperature(temperature)
      end
    else
      RubyLLM.chat(model: model).with_temperature(temperature)
    end
  end

  private

  # Strips markdown code fences (```json ... ``` or ``` ... ```) that some
  # LLM providers/gateways wrap around JSON responses despite response_format hints.
  def sanitize_json_response(response)
    return response if response.nil?

    response.strip.sub(/\A```(?:\w*)\s*\n?/, '').sub(/\n?\s*```\s*\z/, '').strip
  end

  def setup_model
    user_model = openai_hook&.settings&.dig('model') if @account && user_hook_key_allowed? && user_hook_api_key.present? && !system_api_key_available?
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = user_model.presence || config_value.presence || DEFAULT_MODEL
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
