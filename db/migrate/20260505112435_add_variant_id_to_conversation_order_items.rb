class AddVariantIdToConversationOrderItems < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_order_items, :variant_id, :string
  end
end
