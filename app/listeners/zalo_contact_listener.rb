class ZaloContactListener < BaseListener
  def contact_updated(event)
    contact = event.data[:contact]
    changed_attributes = event.data[:changed_attributes] || {}

    return unless contact
    return unless changed_attributes.key?(:label_list) || changed_attributes.key?('label_list')

    # Find if this contact belongs to any Zalo OA
    contact.contact_inboxes.includes(:inbox).find_each do |ci|
      next unless ci.inbox.channel_type == 'Channel::ZaloOa'

      Zalo::ContactTagSyncJob.perform_later(contact.id, ci.inbox.channel_id)
    end
  end
end
