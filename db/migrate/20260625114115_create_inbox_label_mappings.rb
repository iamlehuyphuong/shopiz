class CreateInboxLabelMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_label_mappings do |t|
      t.references :inbox, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true
      t.string :native_label_id, null: false
      t.string :native_label_name, null: false

      t.timestamps
    end

    add_index :inbox_label_mappings, [:inbox_id, :native_label_id], unique: true
  end
end
