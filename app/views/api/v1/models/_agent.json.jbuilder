json.id resource.id
# could be nil for a deleted agent hence the safe operator before account id
json.account_id Current.account&.id
json.availability_status resource.availability_status
json.auto_offline resource.auto_offline
json.confirmed resource.confirmed?
json.email resource.email
json.provider resource.provider
json.available_name resource.available_name
json.custom_attributes resource.custom_attributes if resource.custom_attributes.present?
if Current.account&.id && Integrations::Hook.exists?(account_id: Current.account.id, app_id: 'omicall')
  sip_info = resource.omicall_sip_infos.find_by(account_id: Current.account.id)
  if sip_info
    json.omicall_sip_info do
      json.sip_user sip_info.sip_user
    end
  end
end
json.name resource.name
json.role resource.role
json.thumbnail resource.avatar_url
json.custom_role_id resource.current_account_user&.custom_role_id if ChatwootApp.enterprise?
