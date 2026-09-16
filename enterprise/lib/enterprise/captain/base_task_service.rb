module Enterprise::Captain::BaseTaskService
  def perform
    unless captain_tasks_enabled?
      return { error: I18n.t('captain.upgrade') } if ChatwootApp.chatwoot_cloud?

      return { error: I18n.t('captain.disabled') }
    end

    # When system credits are exhausted but user has their own OpenAI key:
    # Use user's key without deducting system credits
    if !system_responses_available? && user_hook_key_available?
      Rails.logger.info(
        "[CAPTAIN][#{self.class.name}] Using user hook API key for account #{account.id} (system credits exhausted)"
      )
      @api_key = user_hook_api_key
      return super
    end

    # Normal flow: check system credits
    return { error: I18n.t('captain.copilot_limit'), error_code: 429 } unless responses_available?

    result = super
    increment_usage if successful_result?(result)
    result
  end

  private

  def system_responses_available?
    return true unless ChatwootApp.chatwoot_cloud?

    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def user_hook_key_available?
    user_hook_key_allowed? && openai_hook&.hook_api_key.present?
  end

  def responses_available?
    return true unless ChatwootApp.chatwoot_cloud?

    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def successful_result?(result)
    result.is_a?(Hash) && result[:message].present? && !result[:error]
  end

  def increment_usage
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{account.id}")
    account.increment_response_usage
  end
end
