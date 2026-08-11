class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation
  include Captain::UserHookKeyHelper

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id

    @embedding_model = if !system_api_key_available? && @account_id && user_hook_key_allowed? && user_hook_api_key.present?
                         user_hook_embedding_model.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
                       else
                         InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
                       end
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

  def user_hook_embedding_model
    openai_hook&.settings&.dig('embedding_model')
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
