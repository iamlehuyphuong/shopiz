class ZaloAutoMessageListener < BaseListener
  def contact_updated(event)
    contact = event.data[:contact]
    changed_attributes = event.data[:changed_attributes] || {}
    account = contact.account

    # 1. Check if phone number was just added or changed
    return unless changed_attributes.key?('phone_number') || changed_attributes.key?(:phone_number)
    return if contact.phone_number.blank?

    # 2. Find inboxes where this contact has interacted
    # We check if any of these inboxes have the feature enabled
    contact_inbox_ids = contact.contact_inboxes.pluck(:inbox_id)
    return if contact_inbox_ids.empty?

    # Find inboxes with feature enabled
    enabled_inboxes = account.inboxes.where(id: contact_inbox_ids).select do |inbox|
      inbox.zalo_auto_message_enabled.to_s == 'true' || inbox.zalo_auto_message_enabled == true
    end

    return if enabled_inboxes.empty?

    # 3. For each enabled inbox, process the auto message
    enabled_inboxes.each do |inbox|
      configured_zalo_inbox_ids = inbox.zalo_auto_message_inbox_ids || []
      next if configured_zalo_inbox_ids.empty?

      valid_zalo_inboxes = account.inboxes.where(id: configured_zalo_inbox_ids, channel_type: 'Channel::ZaloPersonal')
      next if valid_zalo_inboxes.empty?

      # Round robin pick a Zalo Personal inbox
      counter = Redis::Alfred.incr("zalo_auto_message_rr_#{inbox.id}")
      chosen_zalo_inbox = valid_zalo_inboxes[counter % valid_zalo_inboxes.length]

      # Enqueue Job
      ZaloPersonal::AutoSendMessageJob.perform_later(chosen_zalo_inbox.id, contact.phone_number)
    end
  end
end
