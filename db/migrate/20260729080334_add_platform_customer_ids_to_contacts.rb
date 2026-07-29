class AddPlatformCustomerIdsToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :kiotviet_customer_id, :string
    add_index :contacts, :kiotviet_customer_id
    add_column :contacts, :woocommerce_customer_id, :string
    add_index :contacts, :woocommerce_customer_id
  end
end
