class CreateAccountOnboardings < ActiveRecord::Migration[7.1]
  def change
    create_table :account_onboardings do |t|
      t.references :account, null: false, foreign_key: true
      t.string :industry
      t.text :primary_goals, array: true, default: []
      t.string :team_size
      t.string :daily_messages
      t.string :current_crm
      t.boolean :onboarding_completed, default: false

      t.timestamps
    end
  end
end
