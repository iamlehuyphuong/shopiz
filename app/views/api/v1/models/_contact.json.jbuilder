json.additional_attributes resource.additional_attributes
json.availability_status resource.availability_status

can_manage_contact = Current.account_user.blank? || Current.account_user.administrator? || Current.account_user.permissions.include?('contact_manage')

json.email can_manage_contact ? resource.email : MaskingHelper.mask_email(resource.email)
json.id resource.id
json.name resource.name
json.phone_number can_manage_contact ? resource.phone_number : MaskingHelper.mask_phone(resource.phone_number)
json.blocked resource.blocked
json.identifier resource.identifier
json.thumbnail resource.avatar_url
json.custom_attributes resource.custom_attributes
json.birthday resource.birthday
json.gender_id resource.gender_id
json.last_activity_at resource.last_activity_at.to_i if resource[:last_activity_at].present?
json.created_at resource.created_at.to_i if resource[:created_at].present?
# we only want to output contact inbox when its /contacts endpoints
if defined?(with_contact_inboxes) && with_contact_inboxes.present?
  json.contact_inboxes do
    json.array! resource.contact_inboxes do |contact_inbox|
      json.partial! 'api/v1/models/contact_inbox', formats: [:json], resource: contact_inbox
    end
  end
end
