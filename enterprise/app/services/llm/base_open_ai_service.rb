class Llm::BaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze
  def initialize
    #fetch_hook
    @client = OpenAI::Client.new(
      uri_base: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_BASE_URL').value,
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'openai')
  end

  private

  def uri_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    #config_value = (@hook.settings['model'].presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value)
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
