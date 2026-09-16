json.id resource.id
json.app_id resource.app_id
json.status resource.enabled?
json.inbox resource.inbox&.slice(:id, :name)
json.account_id resource.account_id
json.hook_type resource.hook_type

if Current.account_user&.administrator?
  json.settings do
    settings_hash = resource.merged_settings.except('p', 'h')
    resource.class::SECRET_KEYS.each do |key|
      settings_hash[key] = '[FILTERED]' if settings_hash[key].present?
    end
    json.merge! settings_hash.compact
  end
end

json.reference_id resource.reference_id if Current.account_user&.administrator?
