module ActivityMessageHandler
  extend ActiveSupport::Concern

  include AssigneeActivityMessageHandler
  include PriorityActivityMessageHandler
  include LabelActivityMessageHandler
  include SlaActivityMessageHandler
  include TeamActivityMessageHandler

  private

  def create_activity
    user_name = determine_user_name

    handle_status_change(user_name)
    handle_priority_change(user_name)
    handle_label_change(user_name)
    handle_sla_policy_change(user_name)
    handle_auto_follow_up_change(user_name)
  end

  def determine_user_name
    Current.user&.name
  end

  def handle_status_change(user_name)
    return unless saved_change_to_status?

    status_change_activity(user_name)
  end

  def handle_priority_change(user_name)
    return unless saved_change_to_priority?

    priority_change_activity(user_name)
  end

  def handle_label_change(user_name)
    return unless saved_change_to_label_list?

    create_label_change(activity_message_owner(user_name))
  end

  def handle_sla_policy_change(user_name)
    return unless saved_change_to_sla_policy_id?

    sla_change_type = determine_sla_change_type
    create_sla_change_activity(sla_change_type, activity_message_owner(user_name))
  end

  def handle_auto_follow_up_change(user_name)
    return unless saved_change_to_custom_attributes?

    old_attrs, new_attrs = saved_changes['custom_attributes']
    old_cancelled = old_attrs&.dig('auto_follow_up_cancelled')
    new_cancelled = new_attrs&.dig('auto_follow_up_cancelled')

    return if old_cancelled == new_cancelled
    return if old_cancelled.nil? && new_cancelled == false # ignore initial save false

    if new_cancelled
      translation_key = user_name ? 'conversations.activity.auto_follow_up.cancelled_by_user' : 'conversations.activity.auto_follow_up.cancelled_by_system'
      i18n_key = user_name ? 'CONVERSATION.ACTIVITY.auto_follow_up.cancelled_by_user' : 'CONVERSATION.ACTIVITY.auto_follow_up.cancelled_by_system'
    else
      translation_key = user_name ? 'conversations.activity.auto_follow_up.restored_by_user' : 'conversations.activity.auto_follow_up.restored_by_system'
      i18n_key = user_name ? 'CONVERSATION.ACTIVITY.auto_follow_up.restored_by_user' : 'CONVERSATION.ACTIVITY.auto_follow_up.restored_by_system'
    end

    content = user_name ? I18n.t(translation_key, user_name: user_name) : I18n.t(translation_key)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content, i18n_key, user_name ? { user_name: user_name } : {}))
  end

  def status_change_activity(user_name)
    content, translation_key, translation_values = if Current.executed_by.present?
                                                     automation_status_change_activity_content
                                                   else
                                                     user_status_change_activity_content(user_name)
                                                   end

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content, translation_key, translation_values)) if content
  end

  def auto_resolve_message_key(minutes)
    if minutes >= 1440 && (minutes % 1440).zero?
      { key: 'auto_resolved_days', count: minutes / 1440 }
    elsif minutes >= 60 && (minutes % 60).zero?
      { key: 'auto_resolved_hours', count: minutes / 60 }
    else
      { key: 'auto_resolved_minutes', count: minutes }
    end
  end

  def user_status_change_activity_content(user_name)
    if user_name
      key = "conversations.activity.status.#{status}"
      values = { user_name: user_name }
      [I18n.t(key, **values), key, values]
    elsif Current.contact.present? && resolved?
      key = 'conversations.activity.status.contact_resolved'
      values = { contact_name: Current.contact.name.capitalize }
      [I18n.t(key, **values), key, values]
    elsif resolved?
      message_data = auto_resolve_message_key(auto_resolve_after || 0)
      key = "conversations.activity.status.#{message_data[:key]}"
      values = { count: message_data[:count] }
      [I18n.t(key, **values), key, values]
    else
      [nil, nil, nil]
    end
  end

  def automation_status_change_activity_content
    if Current.executed_by.instance_of?(AutomationRule)
      key = "conversations.activity.status.#{status}"
      values = { user_name: I18n.t('automation.system_name') }
      [I18n.t(key, **values), key, values]
    elsif Current.executed_by.instance_of?(Contact)
      Current.executed_by = nil
      key = 'conversations.activity.status.system_auto_open'
      [I18n.t(key), key, {}]
    else
      [nil, nil, nil]
    end
  end

  def activity_message_params(content, translation_key = nil, translation_values = nil)
    params = { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
    if translation_key.present?
      params[:content_attributes] = {
        translation_key: translation_key,
        translation_values: translation_values
      }
    end
    params
  end

  def create_muted_message
    create_mute_change_activity('muted')
  end

  def create_unmuted_message
    create_mute_change_activity('unmuted')
  end

  def create_mute_change_activity(change_type)
    return unless Current.user

    key = "conversations.activity.#{change_type}"
    values = { user_name: Current.user.name }
    content = I18n.t(key, **values)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content, key, values)) if content
  end
end

ActivityMessageHandler.prepend_mod_with('ActivityMessageHandler')
