class AddInvoiceInfoToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :type_id, :integer, default: 0
    add_column :accounts, :address, :string
    add_column :accounts, :company_name, :string
    add_column :accounts, :company_address, :string
    add_column :accounts, :company_email, :string
    add_column :accounts, :company_tax_id, :string
    add_column :accounts, :id_number, :string
  end
end
