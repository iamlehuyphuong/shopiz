class AddMissingIndexesToProductsAndOrders < ActiveRecord::Migration[7.1]
  def change
    add_index :products, [:account_id, :name], name: 'index_products_on_account_id_and_name'
    add_index :products, [:account_id, :external_id], name: 'index_products_on_account_id_and_external_id'
    add_index :conversation_orders, [:account_id, :contact_id], name: 'index_conversation_orders_on_account_id_and_contact_id'
    add_index :conversation_orders, [:account_id, :external_source, :external_order_id],
              name: 'index_conv_orders_on_account_source_external_id'
  end
end
