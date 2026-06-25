class AddReminderNoteToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :reminder_note, :text
  end
end
