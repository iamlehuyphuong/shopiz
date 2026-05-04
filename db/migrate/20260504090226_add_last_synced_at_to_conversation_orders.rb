class AddLastSyncedAtToConversationOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_orders, :last_synced_at, :datetime
    add_index :conversation_orders, :last_synced_at
    add_index :conversation_orders, [:account_id, :created_at]
  end
end
