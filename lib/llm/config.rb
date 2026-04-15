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
  end
end
