class AddEcommerceFieldsToConversationOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_orders, :shipping_fee, :decimal, precision: 15, scale: 2, default: '0.0'
    add_column :conversation_orders, :tax, :decimal, precision: 15, scale: 2, default: '0.0'
    add_column :conversation_orders, :discount_amount, :decimal, precision: 15, scale: 2, default: '0.0'
    add_column :conversation_orders, :shipping_carrier, :string
    add_column :conversation_orders, :tracking_code, :string
    add_column :conversation_orders, :payment_method, :string
    add_column :conversation_orders, :payment_status, :string, default: 'unpaid'
  end
end
