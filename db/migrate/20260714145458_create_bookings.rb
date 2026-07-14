class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: true, foreign_key: true
      t.references :conversation, null: true, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.string :guest_name
      t.string :guest_email
      t.string :google_event_id
      t.string :provider
      t.integer :status

      t.timestamps
    end
  end
end
