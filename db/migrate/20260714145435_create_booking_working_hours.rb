class CreateBookingWorkingHours < ActiveRecord::Migration[7.1]
  def change
    create_table :booking_working_hours do |t|
      t.references :booking_configuration, null: false, foreign_key: true
      t.integer :day_of_week
      t.integer :open_hour
      t.integer :open_minutes
      t.integer :close_hour
      t.integer :close_minutes
      t.boolean :closed_all_day
      t.boolean :open_all_day

      t.timestamps
    end
  end
end
