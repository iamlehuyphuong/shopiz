module Captain::CreditGuard
  extend ActiveSupport::Concern
  include Captain::UserHookKeyHelper

  private

  def system_responses_available?
    return false unless system_api_key_available?
    return true unless ChatwootApp.chatwoot_cloud?

    target_account = respond_to?(:account, true) ? account : @account
    target_account&.usage_limits&.dig(:captain, :responses, :current_available)&.positive? || false
  end

  def user_hook_key_available?
    user_hook_key_allowed? && user_hook_api_key.present?
  end

  def using_user_hook_key_for_credit?
    !system_responses_available? && user_hook_key_available?
  end

  def responses_available?
    system_responses_available? || user_hook_key_available?
  end

  def increment_usage_if_system_key!
    return if using_user_hook_key_for_credit?

    target_account = respond_to?(:account, true) ? account : @account
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{target_account.id}")
    target_account.increment_response_usage
  end
end
