class Conversations::AgentReminderJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Conversation.due_for_reminder.find_each do |conversation|
      send_reminder(conversation)
    end
  end

  private

  def next_reminder_at(conversation)
    current = conversation.reminder_at
    case conversation.reminder_repeat
    when 'daily'   then current + 1.day
    when 'weekly'  then current + 1.week
    when 'monthly' then current + 1.month
    end
  end

  def send_reminder(conversation)
    Conversation.transaction do
      # 1. Save note before clearing
      note = conversation.reminder_note

      # 2. Advance or clear reminder_at depending on repeat setting
      next_at = next_reminder_at(conversation)

      conversation.update!(
        reminder_at: next_at,
        reminder_note: next_at ? conversation.reminder_note : nil
      )

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
