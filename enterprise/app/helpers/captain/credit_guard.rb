module Captain::CreditGuard
  extend ActiveSupport::Concern

  private

  def system_responses_available?
    return true unless ChatwootApp.chatwoot_cloud?

    target_account = respond_to?(:account, true) ? account : @account
    target_account&.usage_limits&.dig(:captain, :responses, :current_available)&.positive? || false
  end

  def user_hook_key_available?
    user_hook_key_allowed? && openai_hook&.settings&.dig('api_key').present?
  end

  def using_user_hook_key_for_credit?
    !system_responses_available? && user_hook_key_available?
  end

  def responses_available?
    system_responses_available? || user_hook_key_available?
  end

  def user_hook_key_allowed?
    return @user_hook_allowed if defined?(@user_hook_allowed)

    config = InstallationConfig.find_by(name: 'CAPTAIN_ALLOW_USER_HOOK_KEY')
    @user_hook_allowed = config.nil? || config.value == true
  end

  def openai_hook
    @openai_hook ||= begin
      target_account = respond_to?(:account, true) ? account : @account
      target_account&.hooks&.find_by(app_id: 'openai', status: 'enabled')
    end
  end

  def user_hook_api_key
    openai_hook&.settings&.dig('api_key')
  end

  def user_hook_api_base
    base = openai_hook&.settings&.dig('api_base_url')
    return nil if base.blank?

    base.chomp('/')
  end

  def increment_usage_if_system_key!
    return if using_user_hook_key_for_credit?

    target_account = respond_to?(:account, true) ? account : @account
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{target_account.id}")
    target_account.increment_response_usage
  end
end
