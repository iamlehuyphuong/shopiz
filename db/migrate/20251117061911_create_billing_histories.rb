class CreateBillingHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :billing_histories do |t|
      t.string :product_id, null: false
      t.string :product_name
      t.string :sku
      t.integer :status
      t.bigint :price_amount
      t.string :price_currency
      t.string :transaction_id
      t.jsonb :metadata, default: {}
      t.string :description
      t.string :transaction_date_time
      t.references :account, null: false

      t.timestamps
    end
  end
end
