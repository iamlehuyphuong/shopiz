class AddMoreUserInfoToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :type_id, :integer, default: 0
    add_column :users, :address, :string
    add_column :users, :company_name, :string
    add_column :users, :company_address, :string
    add_column :users, :company_email, :string
    add_column :users, :company_tax_id, :string
  end
end
