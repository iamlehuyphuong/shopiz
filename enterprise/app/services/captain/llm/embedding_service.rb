class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id
    @embedding_model = InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
  end

  def self.embedding_model
    InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
  end

  def get_embedding(content, model: @embedding_model)
    return [] if content.blank?

    instrument_embedding_call(instrumentation_params(content, model)) do
      if !system_api_key_available? && @account_id && user_hook_key_allowed? && user_hook_api_key.present?
        Llm::Config.with_api_key(user_hook_api_key, api_base: user_hook_api_base) do |context|
          context.embed(content, model: model).vectors
        end
      else
        RubyLLM.embed(content, model: model).vectors
      end
    end
  rescue RubyLLM::Error => e
    Rails.logger.error "Embedding API Error: #{e.message}"
    raise EmbeddingsError, "Failed to create an embedding: #{e.message}"
  end

  private

  def account
    @account ||= Account.find_by(id: @account_id) if @account_id
  end

  def system_api_key_available?
    return @system_api_key_available if defined?(@system_api_key_available)

    @system_api_key_available = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.present?
  end

  def user_hook_key_allowed?
    return @user_hook_key_allowed if defined?(@user_hook_key_allowed)

    config = InstallationConfig.find_by(name: 'CAPTAIN_ALLOW_USER_HOOK_KEY')
    @user_hook_key_allowed = config.nil? || config.value == true
  end

  def openai_hook
    @openai_hook ||= account&.hooks&.find_by(app_id: 'openai', status: 'enabled')
  end

  def user_hook_api_key
    openai_hook&.settings&.dig('api_key')
  end

  def user_hook_api_base
    base = openai_hook&.settings&.dig('api_base_url')
    return nil if base.blank?

    base.chomp('/').delete_suffix('/v1')
  end

  def instrumentation_params(content, model)
    {
      span_name: 'llm.captain.embedding',
      model: model,
      input: content,
      feature_name: 'embedding',
      account_id: @account_id
    }
  end
end
