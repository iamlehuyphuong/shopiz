class CreateZaloPersonal < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_zalo_personal do |t|
      t.string :oa_access_token, null: false
      t.string :refresh_token, null: false
      t.integer :expires_in, null: false
      t.integer :account_id, null: false
      t.string :oa_id, null: false
      t.index :oa_id, name: 'index_channel_zalo_personal_on_oa_id', unique: true
      t.timestamps null: false
    end
  end
end
