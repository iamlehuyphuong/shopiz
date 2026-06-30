class AddReminderRepeatToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :reminder_repeat, :integer, default: 0
  end
end
