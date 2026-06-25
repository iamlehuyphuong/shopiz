class CreateZaloGroupMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :zalo_group_members do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.string :uid
      t.string :name
      t.string :avatar
      t.string :cover
      t.string :bio
      t.string :gender
      t.string :dob
      t.boolean :is_creator
      t.boolean :is_admin

      t.timestamps
    end
    add_index :zalo_group_members, [:conversation_id, :uid], unique: true
  end
end
