# frozen_string_literal: true

# == Schema Information
#
# Table name: account_subscriptions
#
#  id                   :bigint           not null, primary key
#  ends_at              :datetime         not null
#  starts_at            :datetime         not null
#  status               :integer          default("active")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  subscription_plan_id :bigint           not null
#
# Indexes
#
#  index_account_subscriptions_on_account_id            (account_id)
#  index_account_subscriptions_on_status                (status)
#  index_account_subscriptions_on_subscription_plan_id  (subscription_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (subscription_plan_id => subscription_plans.id)
#
class AccountSubscription < ApplicationRecord
  belongs_to :account
  belongs_to :subscription_plan

  enum status: { active: 0, expired: 1, canceled: 2 }

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at

  scope :active, -> { where(status: :active).where('ends_at > ?', Time.current) }

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?

    errors.add(:ends_at, 'must be after starts_at') if ends_at <= starts_at
  end
end
