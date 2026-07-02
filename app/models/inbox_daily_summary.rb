class InboxDailySummary < ApplicationRecord
  belongs_to :account

  validates :summary_instruction, presence: true, if: :enabled?
  validates :reporting_instruction, presence: true, if: :enabled?
  validates :schedule_times, length: { minimum: 1, message: 'must have at least one time scheduled' }, if: :enabled?
end
