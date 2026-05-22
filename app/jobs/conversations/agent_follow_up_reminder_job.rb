class Conversations::AgentFollowUpReminderJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Conversation.due_for_follow_up.find_each do |conversation|
      send_reminder(conversation)
    end
  end

  private

  def send_reminder(conversation)
    Conversation.transaction do
      # 1. Clear follow_up_at to prevent repeated reminders.
      # Use update_column to skip callbacks (no ActionCable broadcast / activity creation needed).
      # rubocop:disable Rails/SkipsModelValidations
      conversation.update_column(:follow_up_at, nil)
      # rubocop:enable Rails/SkipsModelValidations

      # 2. Create the internal (private) note in the account's locale
      I18n.with_locale(conversation.account.locale || I18n.default_locale) do
        content = I18n.t('conversations.follow_up.reminder')
        
        conversation.messages.create!(
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :outgoing,
          private: true,
          content: content
        )
      end
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end
end
