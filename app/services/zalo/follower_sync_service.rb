# Syncs all followers from Zalo OA to Shopiz contacts
# Creates Contact + ContactInbox for each follower and fetches their profile data
# Uses pagination to handle large follower lists
class Zalo::FollowerSyncService
  attr_reader :inbox

  BATCH_SIZE = 50

  def initialize(inbox)
    @inbox = inbox
  end

  def perform
    offset = 0
    loop do
      response = client.get_followers(offset: offset, count: BATCH_SIZE)
      break unless response['error']&.zero?

      followers = response.dig('data', 'followers') || []
      break if followers.empty?

      process_followers(followers)

      total = response.dig('data', 'total') || 0
      offset += BATCH_SIZE
      break if offset >= total
    end
  end

  private

  def channel
    @channel ||= @inbox.channel
  end

  def client
    @client ||= channel.client
  end

  def process_followers(followers)
    followers.each do |follower|
      user_id = follower['user_id']
      next if user_id.blank?

      sync_follower(user_id)
    rescue StandardError => e
      Rails.logger.error "Zalo::FollowerSyncService: Error syncing follower #{user_id}: #{e.message}"
    end
  end

  def sync_follower(user_id)
    contact_inbox = find_or_create_contact(user_id)
    contact = contact_inbox.contact

    # Fetch profile details
    response = client.get_user_detail(user_id)
    return unless response['error']&.zero?

    data = response['data']
    update_contact_profile(contact, data)
  end

  def find_or_create_contact(user_id)
    ::ContactInboxWithContactBuilder.new(
      source_id: user_id,
      inbox: @inbox,
      contact_attributes: { name: user_id }
    ).perform
  end

  def update_contact_profile(contact, data)
    contact.name = data['display_name'] if data['display_name'].present? && (contact.name == contact.contact_inboxes.first&.source_id)
    contact.additional_attributes['zalo_user_id'] = data['user_id']
    contact.additional_attributes['zalo_user_id_by_app'] = data['user_id_by_app']
    contact.additional_attributes['zalo_is_follower'] = true
    contact.additional_attributes['zalo_last_interaction'] = data['user_last_interaction_date']

    sync_shared_info(contact, data['shared_info']) if data['shared_info'].present?

    contact.save!
    avatar_url = data.dig('avatars', '240') || data['avatar']
    ::Avatar::AvatarFromUrlJob.perform_later(contact, avatar_url) if avatar_url.present?
  end

  def sync_shared_info(contact, shared_info)
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
end
