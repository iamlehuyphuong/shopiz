class AddUniqueIndexesToSalesModels < ActiveRecord::Migration[7.1]
  def change
    remove_index :conversation_orders, name: 'index_conv_orders_on_account_source_external_id', if_exists: true
    add_index :conversation_orders, [:account_id, :external_source, :external_order_id], unique: true,
                                                                                         name: 'index_conv_orders_on_account_source_external_id'

    remove_index :products, name: 'index_products_on_account_id_and_external_id', if_exists: true
    add_index :products, [:account_id, :external_id], unique: true, name: 'index_products_on_account_id_and_external_id'
  end
end
