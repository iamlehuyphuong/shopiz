# Handles Zalo OA 'user_submit_info' webhook event
# When a user submits their personal info (phone, address, etc.) through the OA's info request form,
# this service syncs that data to the corresponding Shopiz Contact record
#
# Webhook payload structure:
# {
#   "event_name": "user_submit_info",
#   "sender": { "id": "<user_id>" },
#   "recipient": { "id": "<oa_id>" },
#   "info": {
#     "phone": "0901234567",
#     "address": "123 Nguyen Hue, Q1",
#     "city": "Ho Chi Minh",
#     "district": "Quan 1",
#     "name": "Nguyen Van A"
#   }
# }
class Zalo::UserInfoService
  pattr_initialize [:inbox!, :params!]

  def perform
    contact_inbox = @inbox.contact_inboxes.find_by(source_id: user_id)
    return unless contact_inbox

    @contact = contact_inbox.contact
    sync_personal_info
    @contact.save!

    Rails.logger.info "Zalo::UserInfoService: synced info for contact #{@contact.id} from user #{user_id}"
  end

  private

  def user_id
    params[:sender][:id]
  end

  def info
    params[:info] || {}
  end

  def sync_personal_info
    sync_phone
    sync_address
    sync_name
  end

  def sync_phone
    return if info['phone'].blank?

    phone = info['phone']
    # Convert Vietnamese local format (0xxx) to international (+84xxx)
    phone = "+84#{phone[1..]}" if phone.start_with?('0')
    @contact.phone_number = phone if @contact.phone_number.blank?
    @contact.additional_attributes['zalo_phone'] = info['phone']
  end

  def sync_address
    return if info['address'].blank?

    @contact.location = info['address']
    @contact.additional_attributes['city'] = info['city'] if info['city'].present?
    @contact.additional_attributes['district'] = info['district'] if info['district'].present?
    @contact.additional_attributes['ward'] = info['ward'] if info['ward'].present?
  end

  def sync_name
    return if info['name'].blank?

    @contact.name = info['name'] if @contact.name == user_id || @contact.name.blank?
    @contact.additional_attributes['zalo_name'] = info['name']
  end
end
