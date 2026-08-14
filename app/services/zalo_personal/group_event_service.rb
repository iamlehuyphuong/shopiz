class ZaloPersonal::GroupEventService
  pattr_initialize [:inbox!, :params!]

  def perform
    conversation = find_conversation
    return unless conversation

    create_activity_message(conversation)
  end

  private

  def find_conversation
    group_id = params[:groupId] || params[:group_id]
    @inbox.conversations.find_by(external_source_id: group_id)
  end

  def create_activity_message(conversation)
    content = build_message_content
    conversation.messages.create!(
      message_type: :activity,
      content: content,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id
    )
  end

  def build_message_content
    case params[:type] || params[:act] || params[:event]
    when 'join', 'join_request', 'JOIN_GROUP'
      members = extract_members
      "Sự kiện nhóm: Thành viên đã tham gia nhóm#{members.present? ? " (User ID: #{members})" : ''}"
    when 'leave', 'LEAVE_GROUP'
      members = extract_members
      "Sự kiện nhóm: Thành viên đã rời nhóm#{members.present? ? " (User ID: #{members})" : ''}"
    when 'remove_member', 'block_member'
      members = extract_members
      "Sự kiện nhóm: Thành viên bị xóa/chặn khỏi nhóm#{members.present? ? " (User ID: #{members})" : ''}"
    when 'add_admin'
      members = extract_members
      "Sự kiện nhóm: Thêm quản trị viên mới#{members.present? ? " (User ID: #{members})" : ''}"
    when 'remove_admin'
      members = extract_members
      "Sự kiện nhóm: Xóa quyền quản trị viên#{members.present? ? " (User ID: #{members})" : ''}"
    when 'update', 'update_setting', 'new_link', 'update_avatar', 'UPDATE_GROUP_NAME', 'UPDATE_NAME'
      'Sự kiện nhóm: Nhóm đã được cập nhật thông tin/cài đặt'
    when 'new_pin_topic', 'update_pin_topic', 'reorder_pin_topic', 'unpin_topic'
      'Sự kiện nhóm: Cập nhật ghim tin nhắn'
    when 'update_board', 'remove_board', 'update_topic', 'remove_topic'
      'Sự kiện nhóm: Cập nhật thông báo/bình chọn nhóm'
    when 'remind_topic', 'accept_remind', 'reject_remind'
      'Sự kiện nhóm: Cập nhật nhắc hẹn'
    else
      "Sự kiện nhóm: #{params[:type] || params[:act] || params[:event]}"
    end
  end

  def extract_members
    # join_request uses `uids` array
    return Array(params[:uids]).join(', ') if params[:uids].present?

    members = Array(params[:updateMembers])
    return params[:targetId] if members.blank? && params[:targetId].present?
    
    # Handle both object array [{id: '...'}, ...] and string array ['...', ...]
    members.map do |m|
      m.is_a?(Hash) ? (m[:id] || m['id']) : m.to_s
    end.compact.reject(&:blank?).join(', ')
  end
end
