class AddSkuToBillingModels < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_plans, :sku, :string
    add_index :subscription_plans, :sku, unique: true

    add_column :addon_packages, :sku, :string
    add_index :addon_packages, :sku, unique: true
  end
end
