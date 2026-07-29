class CreateBookingConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :booking_configurations do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :meeting_duration
      t.integer :buffer_time
      t.string :booking_link_hash
      t.boolean :is_active

      t.timestamps
    end
  end
end
