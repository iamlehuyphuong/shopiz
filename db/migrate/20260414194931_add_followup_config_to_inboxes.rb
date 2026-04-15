class AddFollowupConfigToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :followup_config, :jsonb, default: {}
  end
end
