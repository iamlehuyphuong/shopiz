can_manage_contact = Current.account_user.blank? || Current.account_user.administrator? || Current.account_user.permissions.include?('contact_manage')

json.email can_manage_contact ? contact.email : MaskingHelper.mask_email(contact.email)
json.id contact.id
json.name contact.name
json.phone_number can_manage_contact ? contact.phone_number : MaskingHelper.mask_phone(contact.phone_number)
json.identifier contact.identifier
json.additional_attributes contact.additional_attributes
json.last_activity_at contact.last_activity_at&.to_i
