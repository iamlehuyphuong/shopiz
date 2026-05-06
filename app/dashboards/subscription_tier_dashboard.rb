require "administrate/base_dashboard"

class SubscriptionTierDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name_en: Field::String,
    name_vi: Field::String,
    description_en: Field::Text,
    description_vi: Field::Text,
    limits: SubscriptionPlanLimitsField,
    features: SubscriptionPlanFeaturesField,
    visible: Field::Boolean,
    is_free: Field::Boolean,
    subscription_plans: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name_en
    name_vi
    is_free
    visible
    subscription_plans
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name_en
    name_vi
    description_en
    description_vi
    limits
    features
    visible
    is_free
    subscription_plans
  ].freeze

  FORM_ATTRIBUTES = %i[
    name_en
    name_vi
    description_en
    description_vi
    limits
    features
    visible
    is_free
  ].freeze

  def display_resource(subscription_tier)
    "Subscription Tier ##{subscription_tier.id} - #{subscription_tier.name_en}"
  end
end
