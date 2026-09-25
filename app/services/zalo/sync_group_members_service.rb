class Zalo::SyncGroupMembersService
  def initialize(conversation)
    @conversation = conversation
    @inbox = conversation.inbox
    @channel = @inbox.channel
    @account = @inbox.account
  end

  def perform
    return unless @channel.is_a?(Channel::ZaloOa)

    group_id = @conversation.contact_inbox.source_id
    client = @channel.client

    # 1. Fetch group info to get roles (admins/creators)
    info_res = client.get_group_info(group_id)
    return unless info_res['error'] == 0

    group_data = info_res['data'] || {}
    # Zalo GMF group info usually contains admin list and creator
    admin_ids = Array(group_data['admins']).map { |a| a.is_a?(Hash) ? (a['id'] || a['user_id']) : a }.compact
    creator_id = group_data['creator_id']

    # 2. Fetch all members
    members_res = client.get_group_members(group_id)
    return unless members_res['error'] == 0

    members_data = members_res['data'] || []
    # Could be an array of hashes or array of strings, handle both
    uids = members_data.map { |m| m.is_a?(Hash) ? (m['id'] || m['user_id']) : m }.compact.uniq

    # Remove members who left
    @conversation.zalo_group_members.where.not(uid: uids).destroy_all

    return if uids.empty?

    # 3. Fetch detailed user info and build upsert data
    upsert_data = uids.map do |uid|
      # Fetch detail to get avatar, name, gender, dob. It might fail if user blocked OA.
      user_res = client.get_user_detail(uid)
      profile = user_res['error'] == 0 ? (user_res['data'] || {}) : {}

      is_admin = admin_ids.include?(uid) || creator_id == uid

      gender_str = case profile['user_gender'] || profile['gender']
                   when 1 then 'Nam'
                   when 2 then 'Nữ'
                   else 'Chưa cập nhật'
                   end

      {
        account_id: @account.id,
        conversation_id: @conversation.id,
        uid: uid,
        name: profile['display_name'] || profile['name'] || "Zalo User #{uid}",
        avatar: profile['avatar'] || profile['avatars']&.dig('240'),
        cover: profile['cover'],
        bio: profile['status'] || profile['bio'],
        gender: gender_str,
        dob: profile['birth_date'] || profile['dob'],
        is_creator: creator_id == uid,
        is_admin: is_admin,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    # 4. Upsert into database
    ZaloGroupMember.upsert_all(
      upsert_data,
      unique_by: :index_zalo_group_members_on_conversation_id_and_uid,
      update_only: [:name, :avatar, :cover, :bio, :gender, :dob, :is_creator, :is_admin]
    )
  end
end
