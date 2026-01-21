class AddSomeFieldsToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :birthday, :date
    add_column :contacts, :gender_id, :integer
    add_column :contacts, :biography, :text
  end
end
