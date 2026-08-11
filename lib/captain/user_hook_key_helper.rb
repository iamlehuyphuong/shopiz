module Captain::UserHookKeyHelper
  extend ActiveSupport::Concern

  private

  def target_account
    respond_to?(:account, true) ? account : @account
  end

  def user_hook_key_allowed?
    return @user_hook_allowed if defined?(@user_hook_allowed)

    config = InstallationConfig.find_by(name: 'CAPTAIN_ALLOW_USER_HOOK_KEY')
    @user_hook_allowed = config.nil? || config.value == true
  end

  def openai_hook
    return nil unless target_account

    @openai_hook ||= target_account.hooks.find_by(app_id: 'openai', status: 'enabled')
  end

  def user_hook_api_key
    openai_hook&.settings&.dig('api_key')
  end

  def user_hook_api_base
    base = openai_hook&.settings&.dig('api_base_url')
    return nil if base.blank?

    base.chomp('/').sub(%r{/v1\z}, '')
  end

  def system_api_key_available?
    return @system_api_key_available if defined?(@system_api_key_available)

    @system_api_key_available = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.present?
  end

  def system_api_key
    return @system_api_key if defined?(@system_api_key)

    @system_api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  def system_openai_endpoint
    return @system_openai_endpoint if defined?(@system_openai_endpoint)

    @system_openai_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
  end
end
