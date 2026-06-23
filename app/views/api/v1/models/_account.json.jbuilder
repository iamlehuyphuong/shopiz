json.settings resource.settings
json.created_at resource.created_at
json.custom_attributes do
  if resource.active_subscription.present?
    json.plan_name resource.active_subscription.subscription_plan&.name_en&.downcase
    json.sku "PLAN_#{resource.active_subscription.subscription_plan_id}"
    json.stripe_product_id resource.active_subscription.subscription_plan_id
    json.subscription_status resource.active_subscription.status
    json.subscription_ends_on resource.active_subscription.ends_at&.to_date&.to_s
    if resource.active_subscription.status == 'expired' && resource.active_subscription.ends_at.present?
      json.grace_period_ends_at (resource.active_subscription.ends_at + 3.days).to_s
    end
  else
    # Fallback to legacy
    json.plan_name resource.custom_attributes&.dig('plan_name') || 'free'
    json.subscription_status resource.custom_attributes&.dig('subscription_status') || 'active'
    json.subscription_ends_on resource.custom_attributes&.dig('subscription_ends_on')
  end

  json.captain_responses_credit resource.limits&.dig('captain_responses_credit').to_i

  if resource.custom_attributes.present?
    json.industry resource.custom_attributes['industry'] if resource.custom_attributes['industry'].present?
    json.company_size resource.custom_attributes['company_size'] if resource.custom_attributes['company_size'].present?
    json.timezone resource.custom_attributes['timezone'] if resource.custom_attributes['timezone'].present?
    json.logo resource.custom_attributes['logo'] if resource.custom_attributes['logo'].present?
    json.onboarding_step resource.custom_attributes['onboarding_step'] if resource.custom_attributes['onboarding_step'].present?
    json.marked_for_deletion_at resource.custom_attributes['marked_for_deletion_at'] if resource.custom_attributes['marked_for_deletion_at'].present?
    if resource.custom_attributes['marked_for_deletion_reason'].present?
      json.marked_for_deletion_reason resource.custom_attributes['marked_for_deletion_reason']
    end
  end
end

json.onboarding do
  if resource.onboarding.present?
    json.industry resource.onboarding.industry
    json.primary_goals resource.onboarding.primary_goals
    json.team_size resource.onboarding.team_size
    json.daily_messages resource.onboarding.daily_messages
    json.current_crm resource.onboarding.current_crm
    json.onboarding_completed resource.onboarding.onboarding_completed
  else
    json.onboarding_completed resource.custom_attributes&.dig('onboarding_completed') || false
  end
end
json.domain @account.domain
json.features @account.enabled_features
json.id @account.id
json.locale @account.locale
json.name @account.name
json.support_email @account.support_email
json.status @account.status
json.cache_keys @account.cache_keys
json.captain_api_source begin
  system_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.present?
  user_hook = @account.hooks.find_by(app_id: 'openai', status: 'enabled')&.settings&.dig('api_key').present?
  allow_hook = (config = InstallationConfig.find_by(name: 'CAPTAIN_ALLOW_USER_HOOK_KEY')).nil? || config&.value == true

  if system_key
    'system'
  elsif allow_hook && user_hook
    'user_hook'
  else
    'none'
  end
end
