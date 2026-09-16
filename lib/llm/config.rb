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

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil)
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
      end

      Thread.current[:ruby_llm_config] = context.instance_variable_get(:@config)
      begin
        yield context
      ensure
        Thread.current[:ruby_llm_config] = nil
      end
    end

    private

    def configure_ruby_llm
      api_key = system_api_key
      endpoint = openai_endpoint
      # For standard OpenAI endpoints, keep nil so RubyLLM uses built-in defaults.
      normalized_endpoint = (endpoint.chomp('/') if endpoint.present? && !endpoint.chomp('/').match?(%r{\Ahttps://api\.openai\.com(/v1)?\z}))

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
  end
end
