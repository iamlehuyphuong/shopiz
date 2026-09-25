class CreateProductVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :product_variants do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :name
      t.string :sku
      t.string :barcode
      t.decimal :price, precision: 15, scale: 2, default: '0.0'
      t.decimal :compare_at_price, precision: 15, scale: 2
      t.integer :inventory_quantity, default: 0
      t.decimal :weight, precision: 10, scale: 2, default: '0.0'
      t.string :external_id
      t.jsonb :meta, default: {}

      t.timestamps
    end
  end
end
