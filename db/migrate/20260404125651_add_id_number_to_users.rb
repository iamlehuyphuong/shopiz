class AddIdNumberToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :id_number, :string
  end
end
