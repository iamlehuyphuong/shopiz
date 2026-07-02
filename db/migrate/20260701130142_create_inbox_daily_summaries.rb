class CreateInboxDailySummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_daily_summaries do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true, name: 'index_inbox_daily_summaries_unique_on_account_id' }
      t.integer :inbox_ids, array: true, default: []
      t.boolean :enabled, default: false
      t.text :summary_instruction
      t.text :reporting_instruction
      t.jsonb :schedule_times, default: []
      t.integer :user_ids, array: true, default: []
      t.string :timezone, default: 'UTC'
      t.datetime :last_run_at

      t.timestamps
    end
  end
end
