class AddZaloAutoMessageConfigToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :zalo_auto_message_config, :jsonb, default: {}
  end
end
