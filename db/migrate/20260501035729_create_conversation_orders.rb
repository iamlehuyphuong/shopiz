class CreateConversationOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_orders do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false, index: true
      t.references :contact, index: true

      t.integer :status, default: 0, null: false
      t.string :customer_name
      t.string :customer_phone
      t.text :customer_address
      t.text :customer_note
      t.decimal :total_amount, precision: 15, scale: 2, default: 0
      t.string :currency, default: 'VND'
      t.string :external_order_id
      t.string :external_source

      t.timestamps
    end

    create_table :conversation_order_items do |t|
      t.references :conversation_order, null: false, index: true
      t.string :product_name, null: false
      t.string :product_id
      t.string :product_source
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 15, scale: 2, default: 0
      t.decimal :total_price, precision: 15, scale: 2, default: 0
      t.string :product_thumbnail
      t.jsonb :product_metadata, default: {}

      t.timestamps
    end

    add_index :conversation_orders, [:account_id, :conversation_id]
    add_index :conversation_orders, :status
  end
end
