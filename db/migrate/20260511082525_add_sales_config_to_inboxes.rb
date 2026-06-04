class AddSalesConfigToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :sales_config, :jsonb, default: {}
  end
end
