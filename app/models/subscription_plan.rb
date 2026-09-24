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
  belongs_to :subscription_tier
  has_many :account_subscriptions, dependent: :restrict_with_error
  has_many :accounts, through: :account_subscriptions

  delegate :description, :description_en, :description_vi,
           :is_free, :is_free?, to: :subscription_tier, allow_nil: true

  def name(locale = 'en')
    subscription_tier&.name(locale)
  end

  def name_en
    subscription_tier&.name_en
  end

  def name_vi
    subscription_tier&.name_vi
  end

  AI_FEATURES = %w[captain captain_task].freeze
  AI_LIMITS = %w[captain_assistants captain_responses captain_documents captain_faqs].freeze

  def features
    base_features = subscription_tier&.features || {}
    return base_features if ai_included?

    base_features.except(*AI_FEATURES)
  end

  def limits
    base_limits = subscription_tier&.limits || {}
    return base_limits if ai_included?

    base_limits.except(*AI_LIMITS)
  end

  validates :sku, presence: true, uniqueness: true
  validates :duration_days, presence: true, numericality: { greater_than: 0 }
  validates :price_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :visible, -> { where(visible: true) }
  scope :free_plan, -> { joins(:subscription_tier).where(subscription_tiers: { is_free: true }) }

  before_save :ensure_single_default_plan

  private

  def ensure_single_default_plan
    if is_default_for_new_account? && is_default_for_new_account_changed?
      SubscriptionPlan.where.not(id: id).update_all(is_default_for_new_account: false)
    end
  end
end
