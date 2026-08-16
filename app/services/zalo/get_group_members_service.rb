class Zalo::GetGroupMembersService
  def initialize(conversation)
    @conversation = conversation
    @inbox = conversation.inbox
    @channel = @inbox.channel
    @account = @inbox.account
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def perform
    return [] unless @channel.is_a?(Channel::ZaloOa)

    db_members = @conversation.zalo_group_members.order(created_at: :asc)
    uids = db_members.map(&:uid)
    return [] if uids.empty?

    # For OA, we might want to map with contacts if there are any that follow OA
    local_contacts = @account.contacts.where("additional_attributes ->> 'zalo_user_id' IN (?)", uids)
    contacts_by_zalo_id = local_contacts.index_by { |c| c.additional_attributes['zalo_user_id'] }

    db_members.map do |member|
      contact = contacts_by_zalo_id[member.uid]
      is_follower = contact&.additional_attributes&.dig('zalo_is_follower')

      {
        uid: member.uid,
        name: member.name.presence || contact&.name || 'Zalo User',
        avatar: member.avatar,
        phone_number: contact&.phone_number,
        is_admin: member.is_admin,
        is_creator: member.is_creator,
        is_friend: false, # Zalo OA doesn't have "friend" concept, only follower
        is_follower: is_follower,
        is_you: member.uid == @channel.oa_id,
        contact_id: contact&.id,
        bio: member.bio,
        gender: member.gender,
        dob: member.dob,
        cover: member.cover
      }
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def sync!
    return unless @channel.is_a?(Channel::ZaloOa)

    Zalo::SyncGroupMembersService.new(@conversation).perform
  end
end
