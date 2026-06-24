class ZaloPersonal::GetGroupMembersService
  def initialize(conversation)
    @conversation = conversation
    @inbox = conversation.inbox
    @channel = @inbox.channel
    @account = @inbox.account
  end

  def perform
    return [] unless @channel.is_a?(Channel::ZaloPersonal)

    group_id = @conversation.external_source_id
    
    # 1. Get Group Info to fetch uids and roles
    group_info_response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getGroupInfo",
      body: { groupId: group_id, ownId: @channel.oa_access_token }.to_json,
      headers: ZaloPersonal::ApiHelper.request_headers
    )
    
    return [] unless group_info_response['success']
    
    grid_info = group_info_response.dig('data', 'gridInfoMap', group_id) || {}
    
    mem_ver_list = grid_info['memVerList'] || []
    admin_ids = grid_info['adminIds'] || []
    creator_id = grid_info['creatorId']
    
    uids = mem_ver_list.map { |item| item.split('_').first }.compact.uniq
    return [] if uids.empty?

    # 2. Get User Info for members
    members_info_response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      body: { userId: uids, ownId: @channel.oa_id }.to_json,
      headers: ZaloPersonal::ApiHelper.request_headers
    )

    return [] unless members_info_response['success']
    
    profiles = members_info_response.dig('data', 'changed_profiles') || {}
    
    # 3. Map with local contacts for phone_number and friend status
    local_contacts = @account.contacts.where("additional_attributes ->> 'source_id' IN (?)", uids)
    contacts_by_source_id = local_contacts.index_by { |c| c.additional_attributes['source_id'] }

    uids.map do |uid|
      profile = profiles[uid] || {}
      contact = contacts_by_source_id[uid]
      
      is_admin = admin_ids.include?(uid) || creator_id == uid
      
      friend_inbox_ids = contact&.additional_attributes&.dig('zalo_friend_inbox_ids') || contact&.additional_attributes&.dig(:zalo_friend_inbox_ids) || []
      is_friend = friend_inbox_ids.include?(@inbox.id)
      
      gender_str = case profile['gender']
                   when 0 then 'Nam'
                   when 1 then 'Nữ'
                   else 'Chưa cập nhật'
                   end

      {
        uid: uid,
        name: profile['displayName'].presence || profile['zaloName'].presence || contact&.name || 'Zalo User',
        avatar: profile['avatar'],
        phone_number: contact&.phone_number,
        is_admin: is_admin,
        is_creator: creator_id == uid,
        is_friend: is_friend,
        contact_id: contact&.id,
        bio: profile['status'],
        gender: gender_str,
        dob: profile['sdob'],
        cover: profile['cover']
      }
    end
  end
end
