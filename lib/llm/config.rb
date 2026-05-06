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
    def configure_for_account!(account)
      return if system_api_key.present? # Already configured with system key
      return unless account && user_hook_key_allowed?

      hook = account.hooks.find_by(app_id: 'openai', status: 'enabled')
      hook_api_key = hook&.settings&.dig('api_key')
      return unless hook_api_key.present?

      hook_api_base = hook&.settings&.dig('api_base_url')
      base_url = hook_api_base.present? ? hook_api_base.chomp('/').sub(/\/v1\z/, '') : nil
      model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || DEFAULT_MODEL

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

      RubyLLM.configure do |config|
        config.openai_api_key = api_key if api_key.present?
        config.openai_api_base = endpoint.chomp('/') if endpoint.present?
        config.logger = Rails.logger
      end

      return unless defined?(Agents) && api_key.present?

      Agents.configure do |config|
        config.openai_api_key = api_key
        config.openai_api_base = "#{endpoint.chomp('/')}/v1" if endpoint.present?
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
