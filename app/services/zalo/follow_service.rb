# Handles Zalo OA 'follow' webhook event
# When a user follows the OA, creates a Contact + ContactInbox and fetches their profile
class Zalo::FollowService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    update_contact_from_profile
  end

  private

  def channel
    @channel ||= @inbox.channel
  end

  def client
    @client ||= channel.client
  end

  def follower_id
    params[:follower][:id]
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: follower_id,
      inbox: @inbox,
      contact_attributes: { name: follower_id }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def update_contact_from_profile
    response = client.get_user_detail(follower_id)
    return unless response['error']&.zero?

    data = response['data']
    @contact.name = data['display_name'] if data['display_name'].present?
    @contact.additional_attributes['zalo_user_id'] = data['user_id']
    @contact.additional_attributes['zalo_user_id_by_app'] = data['user_id_by_app']
    @contact.additional_attributes['zalo_is_follower'] = true
    @contact.additional_attributes['zalo_followed_at'] = Time.current.iso8601

    # Sync shared info if user previously shared
    sync_shared_info(data['shared_info']) if data['shared_info'].present?

    @contact.save!

    avatar_url = data.dig('avatars', '240') || data['avatar']
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, avatar_url) if avatar_url.present?
  end

  def sync_shared_info(shared_info)
    if shared_info['phone'].present?
      phone = shared_info['phone']
      phone = "+84#{phone[1..]}" if phone.start_with?('0')
      @contact.phone_number = phone if @contact.phone_number.blank?
    end

    if shared_info['address'].present?
      @contact.location = shared_info['address']
      @contact.additional_attributes['city'] = shared_info['city'] if shared_info['city'].present?
    end

    @contact.additional_attributes['zalo_name'] = shared_info['name'] if shared_info['name'].present?
  end
end
