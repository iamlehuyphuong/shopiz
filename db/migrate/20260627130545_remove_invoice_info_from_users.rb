class RemoveInvoiceInfoFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :type_id, :integer
    remove_column :users, :address, :string
    remove_column :users, :company_name, :string
    remove_column :users, :company_address, :string
    remove_column :users, :company_email, :string
    remove_column :users, :company_tax_id, :string
    remove_column :users, :id_number, :string
  end
end
