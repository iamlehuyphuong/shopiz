# frozen_string_literal: true

class SubscriptionTier < ApplicationRecord
  has_many :subscription_plans, dependent: :destroy

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

  validates :name_en, :name_vi, presence: true

  scope :visible, -> { where(visible: true) }
  scope :free_plan, -> { where(is_free: true) }

  validate :single_free_plan_allowed

  def name(locale = :en)
    locale.to_s == 'vi' ? name_vi : name_en
  end

  def description(locale = :en)
    locale.to_s == 'vi' ? description_vi : description_en
  end

  private

  def single_free_plan_allowed
    return unless is_free?

    other_free_plan = SubscriptionTier.free_plan.where.not(id: id).exists?
    errors.add(:is_free, 'can only be set for one tier') if other_free_plan
  end

  def ensure_json_fields
    self.features ||= {}
    self.limits ||= {}
  end
end
