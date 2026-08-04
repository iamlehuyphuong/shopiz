require 'ruby_llm'
require 'agents'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze

  class << self
    def initialized?
      @initialized ||= false
    end

    def initialize!
      configure_ruby_llm
      @initialized = true
    end

    # Reconfigure RubyLLM and Agents gem with account-level fallback key
    # when system key is not available. Should be called by services that
    # need account context (e.g., AgentRunnerService).
    def configure_for_account!(account, force_user_key: false)
      return if system_api_key.present? && !force_user_key # Already configured with system key
      return unless account && user_hook_key_allowed?

      hook = account.hooks.find_by(app_id: 'openai', status: 'enabled')
      hook_api_key = hook&.settings&.dig('api_key')
      return unless hook_api_key.present?

      hook_api_base = hook&.settings&.dig('api_base_url')
      # For standard OpenAI endpoints, keep nil so RubyLLM/Agents use built-in defaults.
      base_url = if hook_api_base.present? && !hook_api_base.chomp('/').match?(%r{\Ahttps://api\.openai\.com(/v1)?\z})
                   hook_api_base.chomp('/').sub(%r{/v1\z}, '')
                 end
      user_model = hook&.settings&.dig('model')
      model = user_model.presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || DEFAULT_MODEL

      RubyLLM.configure do |config|
        config.openai_api_key = hook_api_key
        config.openai_api_base = base_url if base_url.present?
        config.logger = Rails.logger
      end

      return unless defined?(Agents)

      Agents.configure do |config|
        config.openai_api_key = hook_api_key
        config.openai_api_base = "#{base_url}/v1" if base_url.present?
        config.default_model = model
        config.debug = false
      end
    end

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil)
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
      end

      yield context
    end

    private

    def configure_ruby_llm
      api_key = system_api_key
      endpoint = openai_endpoint
      # For standard OpenAI endpoints, keep nil so RubyLLM uses built-in defaults.
      normalized_endpoint = if endpoint.present? && !endpoint.chomp('/').match?(%r{\Ahttps://api\.openai\.com(/v1)?\z})
                              endpoint.chomp('/')
                            end

      RubyLLM.configure do |config|
        config.openai_api_key = api_key if api_key.present?
        config.openai_api_base = normalized_endpoint if normalized_endpoint.present?
        config.logger = Rails.logger
      end

      return unless defined?(Agents) && api_key.present?

      Agents.configure do |config|
        config.openai_api_key = api_key
        config.openai_api_base = "#{normalized_endpoint}/v1" if normalized_endpoint.present?
        config.default_model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || DEFAULT_MODEL
        config.debug = false
      end
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end

    def user_hook_key_allowed?
      config = InstallationConfig.find_by(name: 'CAPTAIN_ALLOW_USER_HOOK_KEY')
      config.nil? || config.value == true
    end
  end
end
