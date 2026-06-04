class AddAutoLabelEnabledToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :auto_label_enabled, :boolean, default: false, null: false
  end
end
