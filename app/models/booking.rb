class Booking < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :conversation
end
