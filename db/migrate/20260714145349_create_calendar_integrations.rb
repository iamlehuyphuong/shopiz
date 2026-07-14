class CreateCalendarIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :calendar_integrations do |t|
      t.references :account, null: false, foreign_key: true
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.string :email
      t.string :provider

      t.timestamps
    end
  end
end
