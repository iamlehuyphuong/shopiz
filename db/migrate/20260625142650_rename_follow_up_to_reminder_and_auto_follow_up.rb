class RenameFollowUpToReminderAndAutoFollowUp < ActiveRecord::Migration[7.1]
  def change
    rename_column :conversations, :follow_up_at, :reminder_at
    rename_column :conversations, :follow_up_remind_before, :reminder_remind_before
    rename_column :conversations, :follow_up_remind_at, :remind_at
    rename_column :inboxes, :followup_config, :auto_follow_up_config
  end
end
