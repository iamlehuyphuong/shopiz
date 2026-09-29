class AddPaymentQrDataToConversationOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_orders, :payment_qr_data, :text
  end
end
