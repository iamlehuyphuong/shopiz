class RestoreEmailNotificationColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :enable_email_collect, :boolean, default: true
    add_column :channel_web_widgets, :continuity_via_email, :boolean, default: true, null: false
  end
end
