class AddEcommerceFieldsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :inventory_quantity, :integer, default: 0
    add_column :products, :images, :jsonb, default: []
  end
end
