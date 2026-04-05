class CreateSubscriptionAndResourceManagement < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_plans do |t|
      t.string :name_en, null: false
      t.string :name_vi, null: false
      t.text :description_en
      t.text :description_vi
      t.decimal :price_amount, precision: 15, scale: 2, default: 0.0
      t.string :currency, default: 'vnd'
      t.integer :duration_days, null: false
      t.jsonb :limits, default: {}
      t.jsonb :features, default: {}
      t.boolean :is_free, default: false
      t.index :is_free
      t.boolean :visible, default: true

      t.timestamps
    end

    create_table :addon_packages do |t|
      t.string :name, null: false
      t.integer :addon_type, null: false # enum: ai_messages, staff, inboxes
      t.integer :quantity, null: false
      t.decimal :price_amount, precision: 15, scale: 2, default: 0.0
      t.string :currency, default: 'vnd'
      t.integer :duration_days # null means no expiration
      t.boolean :visible, default: true

      t.timestamps
    end

    create_table :account_subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, default: 0 # enum: active, expired, canceled

      t.timestamps
    end

    create_table :account_addons do |t|
      t.references :account, null: false, foreign_key: true
      t.references :addon_package, null: false, foreign_key: true
      t.integer :addon_type, null: false
      t.integer :quantity, null: false
      t.datetime :purchased_at, null: false
      t.datetime :expired_at # null means no expiration

      t.timestamps
    end

    add_index :account_subscriptions, :status
    add_index :account_addons, :addon_type
    add_index :account_addons, :expired_at
  end
end
