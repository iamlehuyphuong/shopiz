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
    event_type = params[:type] || params[:act] || params[:event]
    members = extract_members
    user_info = members.present? ? I18n.t('zalo_personal.group_events.user_info', members: members) : ''

    case event_type
    when 'join', 'join_request', 'JOIN_GROUP'
      I18n.t('zalo_personal.group_events.member_joined', user_info: user_info)
    when 'leave', 'LEAVE_GROUP'
      I18n.t('zalo_personal.group_events.member_left', user_info: user_info)
    when 'remove_member', 'block_member'
      I18n.t('zalo_personal.group_events.member_removed', user_info: user_info)
    when 'add_admin'
      I18n.t('zalo_personal.group_events.admin_added', user_info: user_info)
    when 'remove_admin'
      I18n.t('zalo_personal.group_events.admin_removed', user_info: user_info)
    when 'update', 'update_setting', 'new_link', 'update_avatar', 'UPDATE_GROUP_NAME', 'UPDATE_NAME'
      I18n.t('zalo_personal.group_events.group_updated')
    when 'new_pin_topic', 'update_pin_topic', 'reorder_pin_topic', 'unpin_topic'
      I18n.t('zalo_personal.group_events.pin_updated')
    when 'update_board', 'remove_board', 'update_topic', 'remove_topic'
      I18n.t('zalo_personal.group_events.board_updated')
    when 'remind_topic', 'accept_remind', 'reject_remind'
      I18n.t('zalo_personal.group_events.remind_updated')
    else
      I18n.t('zalo_personal.group_events.default', event: event_type)
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
