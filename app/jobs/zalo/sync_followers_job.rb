# Syncs followers from Zalo OA to Shopiz contacts recursively
class Zalo::SyncFollowersJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 50

  def perform(inbox_id, offset = 0) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    channel = inbox.channel
    return unless channel.is_a?(Channel::ZaloOa)

    client = channel.client
    response = client.get_followers(offset: offset, count: BATCH_SIZE)
    return unless response['error']&.zero?

    followers = response.dig('data', 'users') || []
    return if followers.empty?

    process_batch(inbox, client, followers)

    total = response.dig('data', 'total') || 0
    new_offset = offset + BATCH_SIZE

    return unless new_offset < total

    self.class.perform_later(inbox_id, new_offset)
  end

  private

  def process_batch(inbox, client, followers)
    followers.each do |follower|
      user_id = follower['user_id']
      next if user_id.blank?

      contact = sync_follower(inbox, client, user_id)

      if contact
        conversation = find_or_create_conversation(inbox, contact)
        Zalo::LoadHistoryMessageJob.perform_later(conversation.id, 0)
      end
    end
  end

  def sync_follower(inbox, client, user_id)
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: user_id,
      inbox: inbox,
      contact_attributes: { name: user_id }
    ).perform
    contact = contact_inbox.contact

    # Fetch profile
    response = client.get_user_detail(user_id)
    return contact unless response['error']&.zero?

    data = response['data']
    update_contact_profile(contact, contact_inbox, data)

    contact
  rescue StandardError => e
    Rails.logger.error "Zalo::SyncFollowersJob: Error syncing follower #{user_id}: #{e.message}"
    nil
  end

  def update_contact_profile(contact, contact_inbox, data) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    contact.name = data['display_name'] if data['display_name'].present? && (contact.name == contact_inbox.source_id || contact.name.blank?)

    contact.additional_attributes['zalo_user_id'] = data['user_id']
    contact.additional_attributes['zalo_user_id_by_app'] = data['user_id_by_app']
    contact.additional_attributes['zalo_is_follower'] = true
    contact.additional_attributes['zalo_last_interaction'] = data['user_last_interaction_date']

    if data['shared_info'].present?
      shared_info = data['shared_info']
      if shared_info['phone'].present?
        phone = shared_info['phone']
        phone = "+84#{phone[1..]}" if phone.start_with?('0')
        contact.phone_number = phone if contact.phone_number.blank?
      end

      if shared_info['address'].present?
        contact.location = shared_info['address']
        contact.additional_attributes['city'] = shared_info['city'] if shared_info['city'].present?
      end
      contact.additional_attributes['zalo_name'] = shared_info['name'] if shared_info['name'].present?
    end

    contact.save!
    avatar_url = data.dig('avatars', '240') || data['avatar']
    ::Avatar::AvatarFromUrlJob.perform_later(contact, avatar_url) if avatar_url.present?
  end

  def find_or_create_conversation(inbox, contact)
    contact_inbox = contact.contact_inboxes.find_by(inbox_id: inbox.id)
    conversation = contact_inbox.conversations.find_by(
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id
    )

    return conversation if conversation

    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      last_activity_at: Time.current,
      agent_last_seen_at: DateTime.now.utc,
      loaded_from_history: true
    )
  end
end
