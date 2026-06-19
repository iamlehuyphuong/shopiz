class AddFollowUpReminderFieldsToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :follow_up_remind_before, :integer, default: 0
    add_column :conversations, :follow_up_remind_at, :datetime
  end
end
