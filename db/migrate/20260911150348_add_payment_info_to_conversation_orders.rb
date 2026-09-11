class AddPaymentInfoToConversationOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_orders, :payment_provider, :string
    add_column :conversation_orders, :payment_transaction_id, :string
    add_column :conversation_orders, :payment_qr_url, :string
  end
end
