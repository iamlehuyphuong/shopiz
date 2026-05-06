class CreateContactOptins < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_optins do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :token, null: false
      t.string :topic
      t.integer :status, default: 0
      t.datetime :expires_at

      t.timestamps
    end

    add_index :contact_optins, :token, unique: true
  end
end
