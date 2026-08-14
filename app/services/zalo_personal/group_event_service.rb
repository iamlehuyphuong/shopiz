class ZaloPersonal::GroupEventService
  pattr_initialize [:inbox!, :params!]

  def perform
    conversation = find_conversation
    return unless conversation

    create_activity_message(conversation)
  end

  private

  def find_conversation
    @inbox.conversations.find_by(external_source_id: params[:groupId])
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
    case params[:event]
    when 'JOIN_GROUP'
      "Sự kiện nhóm: Thành viên đã tham gia nhóm (User ID: #{params[:targetId]})"
    when 'LEAVE_GROUP'
      "Sự kiện nhóm: Thành viên đã rời nhóm (User ID: #{params[:targetId]})"
    when 'UPDATE_GROUP_NAME', 'UPDATE_NAME'
      'Sự kiện nhóm: Nhóm đã được cập nhật thông tin'
    else
      "Sự kiện nhóm: #{params[:event]}"
    end
  end
end
