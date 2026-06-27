class Conversations::AgentReminderJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Conversation.due_for_reminder.find_each do |conversation|
      send_reminder(conversation)
    end
  end

  private

  def send_reminder(conversation)
    Conversation.transaction do
      # 1. Save note before clearing
      note = conversation.reminder_note

      # 2. Clear reminder fields to stop reminding
      # Use update_columns to skip callbacks (no ActionCable broadcast / activity creation needed).
      # rubocop:disable Rails/SkipsModelValidations
      conversation.update_columns(
        reminder_at: nil,
        remind_at: nil,
        reminder_note: nil,
        custom_attributes: conversation.custom_attributes.except('zalo_reminder_id')
      )
      # rubocop:enable Rails/SkipsModelValidations

      # 3. Create the internal (private) note in the account's locale
      I18n.with_locale(conversation.account.locale || I18n.default_locale) do
        content = I18n.t('conversations.reminder.message')
        content += "\n\n#{I18n.t('conversations.reminder.note', note: note)}" if note.present?
        
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
