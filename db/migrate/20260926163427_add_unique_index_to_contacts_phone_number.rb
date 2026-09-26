class AddUniqueIndexToContactsPhoneNumber < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :contacts, name: :index_contacts_on_phone_number_and_account_id, if_exists: true
    add_index :contacts, [:phone_number, :account_id],
              unique: true,
              where: "phone_number IS NOT NULL AND phone_number != ''",
              name: :uniq_phone_number_per_account_contact,
              algorithm: :concurrently
  end

  def down
    remove_index :contacts, name: :uniq_phone_number_per_account_contact, if_exists: true
    add_index :contacts, [:phone_number, :account_id],
              name: :index_contacts_on_phone_number_and_account_id,
              algorithm: :concurrently
  end
end
