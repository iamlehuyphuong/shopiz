class CreateOmicallSipInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :omicall_sip_infos do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :sip_user
      t.string :sip_password
      t.string :sip_domain
      t.string :outbound_proxy

      t.timestamps
    end
    add_index :omicall_sip_infos, [:account_id, :user_id], unique: true
  end
end
