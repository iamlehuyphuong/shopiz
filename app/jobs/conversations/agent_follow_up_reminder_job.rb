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
      # 1. Track how many reminders have been sent
      count = conversation.custom_attributes['follow_up_reminders_count'].to_i
      
      if count >= 2
        # Max 3 reminders (0, 1, 2). Clear follow_up to stop reminding.
        # Use update_columns to skip callbacks (no ActionCable broadcast / activity creation needed).
        # rubocop:disable Rails/SkipsModelValidations
        conversation.update_columns(
          follow_up_at: nil,
          follow_up_remind_at: nil,
          custom_attributes: conversation.custom_attributes.except('follow_up_reminders_count')
        )
        # rubocop:enable Rails/SkipsModelValidations
      else
        # Increment counter, do NOT clear follow_up_remind_at so it gets picked up again
        # rubocop:disable Rails/SkipsModelValidations
        conversation.update_columns(
          custom_attributes: conversation.custom_attributes.merge('follow_up_reminders_count' => count + 1)
        )
        # rubocop:enable Rails/SkipsModelValidations
      end

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
