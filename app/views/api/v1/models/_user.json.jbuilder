json.access_token resource.access_token.token
json.account_id resource.active_account_user&.account_id
json.available_name resource.available_name
json.avatar_url resource.avatar_url
json.confirmed resource.confirmed?
json.display_name resource.display_name
json.message_signature resource.message_signature
json.email resource.email
json.hmac_identifier resource.hmac_identifier if GlobalConfig.get('CHATWOOT_INBOX_HMAC_KEY')['CHATWOOT_INBOX_HMAC_KEY'].present?
json.id resource.id
json.inviter_id resource.active_account_user&.inviter_id
json.name resource.name

json.provider resource.provider
json.pubsub_token resource.pubsub_token
json.custom_attributes resource.custom_attributes if resource.custom_attributes.present?
account_id = Current.account&.id || resource.active_account_user&.account_id
if account_id && Integrations::Hook.exists?(account_id: account_id, app_id: 'omicall')
  sip_info = resource.omicall_sip_infos.find_by(account_id: account_id)
  if sip_info
    json.omicall_sip_info do
      json.sip_user sip_info.sip_user
      json.sip_password sip_info.sip_password
      json.sip_domain sip_info.sip_domain
      json.outbound_proxy sip_info.outbound_proxy
    end
  end
end
json.role resource.active_account_user&.role
json.ui_settings resource.ui_settings
json.uid resource.uid
json.type resource.type
json.accounts do
  json.array!(resource.account_users.select { |au| au.account.present? }) do |account_user|
    json.id account_user.account_id
    json.name account_user.account&.name
    json.status account_user.account&.status
    json.active_at account_user.active_at
    json.role account_user.role
    json.permissions account_user.permissions
    # the actual availability user has configured
    json.availability account_user.availability
    # availability derived from presence
    json.availability_status account_user.availability_status
    json.auto_offline account_user.auto_offline
    json.partial! 'api/v1/models/account_user', account_user: account_user if ChatwootApp.enterprise?
  end
end
