# frozen_string_literal: true

# DEPRECATED: This class uses the legacy OpenAI Ruby gem directly.
# Only used for PDF/file operations that require OpenAI's files API:
# - Captain::Llm::PdfProcessingService (files.upload for assistants)
# - Captain::Llm::PaginatedFaqGeneratorService (uses file_id from uploaded files)
#
# For all other LLM operations, use Llm::BaseAiService with RubyLLM instead.
class Llm::LegacyBaseOpenAiService
  include Captain::UserHookKeyHelper

  DEFAULT_MODEL = 'gpt-4.1-mini'

  attr_reader :client, :model

  def initialize(account: nil)
    api_key, uri_base_url = resolve_credentials(account)

    @client = OpenAI::Client.new(
      access_token: api_key,
      uri_base: uri_base_url,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise CustomExceptions::LlmConfigurationError, "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def resolve_credentials(account)
    system_api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    return [system_api_key, uri_base] if system_api_key.present?

    user_credentials = fetch_user_credentials(account)
    return user_credentials if user_credentials

    raise 'OpenAI API key not configured'
  end

  def fetch_user_credentials(account)
    return nil unless account && user_hook_key_allowed?

    # We need to temporarily set @account so target_account in helper resolves
    @account = account

    hook_api_key = user_hook_api_key
    return nil if hook_api_key.blank?

    base_url = (user_hook_api_base.presence || uri_base)
    [hook_api_key, base_url]
  end

  # Strips markdown code fences (```json ... ``` or ``` ... ```) that some
  # LLM providers/gateways wrap around JSON responses despite response_format hints.
  def sanitize_json_response(response)
    return response if response.nil?

    response.strip.sub(/\A```(?:\w*)\s*\n?/, '').sub(/\n?\s*```\s*\z/, '').strip
  end

  def uri_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
