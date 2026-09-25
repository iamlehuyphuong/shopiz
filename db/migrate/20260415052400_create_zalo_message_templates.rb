class CreateZaloMessageTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :zalo_message_templates do |t|
      t.string :template_name, null: false
      t.integer :template_type, null: false, default: 0
      t.jsonb :template_content, null: false, default: {}
      t.string :language, default: 'VI'
      t.integer :status, null: false, default: 0
      t.bigint :account_id, null: false
      t.bigint :channel_id, null: false

      t.timestamps
    end

    add_index :zalo_message_templates, :account_id
    add_index :zalo_message_templates, :channel_id
    add_index :zalo_message_templates, [:account_id, :template_name, :channel_id], unique: true,
                                                                                   name: 'idx_zalo_templates_unique'
  end
end
