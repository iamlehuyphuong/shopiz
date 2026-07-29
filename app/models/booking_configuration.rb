class BookingConfiguration < ApplicationRecord
  belongs_to :account
  has_many :booking_working_hours, dependent: :destroy
end
