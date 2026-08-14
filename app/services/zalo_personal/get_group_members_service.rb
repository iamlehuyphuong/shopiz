class ZaloPersonal::GetGroupMembersService
  def initialize(conversation)
    @conversation = conversation
    @inbox = conversation.inbox
    @channel = @inbox.channel
    @account = @inbox.account
  end

  def perform
    return [] unless @channel.is_a?(Channel::ZaloPersonal)

    db_members = @conversation.zalo_group_members.order(created_at: :asc)
    uids = db_members.map(&:uid)
    return [] if uids.empty?

    # Map with local contacts for phone_number and friend status
    local_contacts = @account.contacts.where("additional_attributes ->> 'source_id' IN (?)", uids)
    contacts_by_source_id = local_contacts.index_by { |c| c.additional_attributes['source_id'] }

    db_members.map do |member|
      contact = contacts_by_source_id[member.uid]
      friend_inbox_ids = contact&.additional_attributes&.dig('zalo_friend_inbox_ids') || contact&.additional_attributes&.dig(:zalo_friend_inbox_ids) || []
      is_friend = friend_inbox_ids.include?(@inbox.id)

      {
        uid: member.uid,
        name: member.name.presence || contact&.name || 'Zalo User',
        avatar: member.avatar,
        phone_number: contact&.phone_number,
        is_admin: member.is_admin,
        is_creator: member.is_creator,
        is_friend: is_friend,
        is_you: member.uid == @channel.oa_id,
        contact_id: contact&.id,
        bio: member.bio,
        gender: member.gender,
        dob: member.dob,
        cover: member.cover
      }
    end
  end

  def sync!
    return unless @channel.is_a?(Channel::ZaloPersonal)

    group_id = @conversation.external_source_id

    # 1. Get Group Info to fetch uids and roles
    group_info_response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getGroupInfo",
      body: { groupId: group_id, ownId: @channel.oa_id }.to_json,
      headers: ZaloPersonal::ApiHelper.request_headers
    )

    return unless group_info_response['success']

    grid_info = group_info_response.dig('data', 'gridInfoMap', group_id) || {}

    mem_ver_list = grid_info['memVerList'] || []
    admin_ids = grid_info['adminIds'] || []
    creator_id = grid_info['creatorId']

    uids = mem_ver_list.map { |item| item.split('_').first }.compact.uniq

    # Remove users who left the group
    @conversation.zalo_group_members.where.not(uid: uids).destroy_all

    return if uids.empty?

    # 2. Get User Info for members in batches
    profiles = {}
    uids.each_slice(50) do |uid_batch|
      members_info_response = HTTParty.post(
        "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
        body: {
          userId: uid_batch,
          ownId: @channel.oa_id
        }.to_json,
        headers: ZaloPersonal::ApiHelper.request_headers
      )

      if members_info_response['success']
        batch_profiles = members_info_response.dig('data', 'changed_profiles') || {}
        profiles.merge!(batch_profiles)
      end
    end

    # 2.5 Update friend contacts
    local_contacts = @account.contacts.where("additional_attributes ->> 'source_id' IN (?)", uids).index_by { |c| c.additional_attributes['source_id'] }

    profiles.each do |uid, profile|
      is_fr = [1, true, '1'].include?(profile['isFr'])
      contact = local_contacts[uid]

      if is_fr && contact.nil?
        contact = @account.contacts.create!(
          name: profile['zaloName'].presence || profile['displayName'].presence || 'Zalo User',
          additional_attributes: {
            source_id: uid,
            avatar_url: profile['avatar']
          }
        )
        local_contacts[uid] = contact
      end

      if contact
        attrs = contact.additional_attributes || {}
        inbox_ids = Array(attrs['zalo_friend_inbox_ids'] || attrs[:zalo_friend_inbox_ids] || [])
        if is_fr
          inbox_ids |= [@inbox.id]
        else
          inbox_ids -= [@inbox.id]
        end
        attrs[:zalo_friend_inbox_ids] = inbox_ids.uniq.compact
        attrs['avatar_url'] = profile['avatar'] if profile['avatar'].present?
        attrs[:description] = profile['status'] if profile['status'].present?

        contact.update(additional_attributes: attrs)
      end
    end

    # 3. Upsert into database
    upsert_data = uids.map do |uid|
      profile = profiles[uid] || {}
      is_admin = admin_ids.include?(uid) || creator_id == uid

      gender_str = case profile['gender']
                   when 0 then 'Nam'
                   when 1 then 'Nữ'
                   else 'Chưa cập nhật'
                   end

      {
        account_id: @account.id,
        conversation_id: @conversation.id,
        uid: uid,
        name: profile['zaloName'].presence || profile['displayName'].presence,
        avatar: profile['avatar'],
        cover: profile['cover'],
        bio: profile['status'],
        gender: gender_str,
        dob: profile['sdob'],
        is_creator: creator_id == uid,
        is_admin: is_admin,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    ZaloGroupMember.upsert_all(
      upsert_data,
      unique_by: :index_zalo_group_members_on_conversation_id_and_uid,
      update_only: [:name, :avatar, :cover, :bio, :gender, :dob, :is_creator, :is_admin]
    )
  end
end
