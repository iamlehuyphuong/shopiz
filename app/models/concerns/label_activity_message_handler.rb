module LabelActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_label_added(user_name, labels = [])
    create_label_change_activity('added', user_name, labels)
  end

  def create_label_removed(user_name, labels = [])
    create_label_change_activity('removed', user_name, labels)
  end

  def create_label_change_activity(change_type, user_name, labels = [])
    return unless labels.size.positive?

    key = "conversations.activity.labels.#{change_type}"
    values = { user_name: user_name, labels: labels.join(', ') }
    content = I18n.t(key, **values)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content, key, values)) if content
  end
end
