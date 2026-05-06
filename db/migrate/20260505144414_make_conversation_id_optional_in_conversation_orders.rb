class MakeConversationIdOptionalInConversationOrders < ActiveRecord::Migration[7.1]
  def change
    change_column_null :conversation_orders, :conversation_id, true
  end
end
