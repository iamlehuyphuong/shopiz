class Zalo::GroupManagementService
  def initialize(conversation)
    @conversation = conversation
    @inbox = conversation.inbox
    @channel = @inbox.channel
    @client = @channel.client
    @group_id = @conversation.contact_inbox.source_id
  end

  # Thêm thành viên vào nhóm
  def invite_members(user_ids)
    return unless @channel.is_a?(Channel::ZaloOa)

    body = {
      group_id: @group_id,
      user_ids: Array(user_ids)
    }
    response = @client.invite_member(body)

    sync_members if response['error'] == 0
    response
  end

  # Xoá thành viên khỏi nhóm
  def remove_members(user_ids)
    return unless @channel.is_a?(Channel::ZaloOa)

    body = {
      group_id: @group_id,
      user_ids: Array(user_ids)
    }
    response = @client.remove_members(body)

    sync_members if response['error'] == 0
    response
  end

  # Bổ nhiệm admin
  def add_admins(user_ids)
    return unless @channel.is_a?(Channel::ZaloOa)

    body = {
      group_id: @group_id,
      admin_ids: Array(user_ids)
    }
    response = @client.add_group_admins(body)

    sync_members if response['error'] == 0
    response
  end

  # Bãi nhiệm admin
  def remove_admins(user_ids)
    return unless @channel.is_a?(Channel::ZaloOa)

    body = {
      group_id: @group_id,
      admin_ids: Array(user_ids)
    }
    response = @client.remove_group_admins(body)

    sync_members if response['error'] == 0
    response
  end

  private

  def sync_members
    # Dispatch job to sync in background instead of blocking the current request
    Zalo::SyncGroupMembersJob.perform_later(@conversation.id)
  end
end
