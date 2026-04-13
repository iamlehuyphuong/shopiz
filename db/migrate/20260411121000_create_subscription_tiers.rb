class CreateSubscriptionTiers < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_tiers do |t|
      t.string :name_en, null: false
      t.string :name_vi, null: false
      t.text :description_en
      t.text :description_vi
      t.jsonb :limits, default: {}
      t.jsonb :features, default: {}
      t.boolean :visible, default: true
      t.boolean :is_free, default: false

      t.timestamps
    end
  end
end
