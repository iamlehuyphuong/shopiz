# Syncs Contact Labels from Chatwoot to Zalo OA Tags
class Zalo::ContactTagSyncJob < ApplicationJob
  queue_as :default

  def perform(contact_id, channel_id) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    contact = Contact.find_by(id: contact_id)
    channel = Channel::ZaloOa.find_by(id: channel_id)
    return unless contact && channel

    zalo_user_id = contact.additional_attributes['zalo_user_id']
    return unless zalo_user_id

    client = channel.client
    response = client.get_user_detail(zalo_user_id)
    return unless response['error']&.zero?

    zalo_tags = response.dig('data', 'tags_and_notes_info', 'tag_names') || []
    chatwoot_labels = contact.label_list

    # Tags to add
    tags_to_add = chatwoot_labels - zalo_tags
    tags_to_add.each do |tag|
      client.tag_follower(zalo_user_id, tag)
    end

    # Tags to remove
    tags_to_remove = zalo_tags - chatwoot_labels
    tags_to_remove.each do |tag|
      client.untag_follower(zalo_user_id, tag)
    end
  end
end
