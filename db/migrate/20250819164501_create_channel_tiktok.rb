class CreateChannelTiktok < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_tiktok do |t|
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.integer :expires_in, null: false
      t.integer :account_id, null: false
      t.string :shop_id, null: false, unique: true
      t.string :shop_cipher, null: false, unique: true
      t.index :shop_id, name: 'index_channel_tiktok_on_shop_id', unique: true
      t.index :shop_cipher, name: 'index_channel_tiktok_on_shop_cipher', unique: true
      t.timestamps
    end
  end
end
