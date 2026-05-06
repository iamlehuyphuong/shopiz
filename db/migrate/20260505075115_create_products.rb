class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :price
      t.string :currency
      t.string :sku
      t.string :barcode
      t.integer :status
      t.string :external_id
      t.jsonb :meta

      t.timestamps
    end
  end
end
