# frozen_string_literal: true

# == Schema Information
#
# Table name: subscription_plans
#
#  id             :bigint           not null, primary key
#  currency       :string           default("vnd")
#  description_en :text
#  description_vi :text
#  duration_days  :integer          not null
#  features       :jsonb
#  is_free        :boolean
#  limits         :jsonb
#  name_en        :string           not null
#  name_vi        :string           not null
#  price_amount   :decimal(15, 2)   default(0.0)
#  visible        :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_subscription_plans_on_is_free  (is_free)
#
class SubscriptionPlan < ApplicationRecord
  has_many :account_subscriptions, dependent: :restrict_with_error
  has_many :accounts, through: :account_subscriptions

  AVAILABLE_LIMIT_KEYS = %w[
    agents
    inboxes
    contacts
    automations
    captain_responses
    captain_documents
    captain_assistants
    captain_faqs
    captain_responses_credit
  ].freeze

  SYSTEM_FEATURES = Featurable::FEATURE_LIST.map { |f| f['name'] }.freeze

  before_validation :ensure_json_fields

  private

  def ensure_json_fields
    self.features ||= {}
    self.limits ||= {}
  end
  validates :name_en, :name_vi, presence: true
  validates :duration_days, presence: true, numericality: { greater_than: 0 }
  validates :price_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :visible, -> { where(visible: true) }
  scope :free_plan, -> { where(is_free: true) }

  validate :single_free_plan_allowed

  def name(locale = I18n.locale)
    locale.to_s == 'vi' ? name_vi : name_en
  end

  def description(locale = I18n.locale)
    locale.to_s == 'vi' ? description_vi : description_en
  end

  private

  def single_free_plan_allowed
    return unless is_free?

    # Check if any other plan is already marked as free
    other_free_plan = SubscriptionPlan.free_plan.where.not(id: id).exists?
    errors.add(:is_free, 'can only be set for one plan') if other_free_plan
  end

  def ensure_json_fields
    self.features ||= {}
    self.limits ||= {}
  end
end
