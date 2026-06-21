require "administrate/base_dashboard"

class SubscriptionPlanDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    subscription_tier: Field::BelongsTo,
    account_subscriptions: Field::HasMany,
    accounts: Field::HasMany,
    currency: Field::String,
    duration_days: Field::Select.with_options(collection: [7, 30, 180, 365, 730]),
    price_amount: Field::String.with_options(searchable: false),
    sku: Field::String,
    visible: Field::Boolean,
    ai_included: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    subscription_tier
    sku
    price_amount
    duration_days
    visible
    ai_included
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    subscription_tier
    sku
    price_amount
    currency
    duration_days
    visible
    ai_included
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    subscription_tier
    sku
    price_amount
    currency
    duration_days
    visible
    ai_included
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(subscription_plan)
    "#{subscription_plan.name_en || subscription_plan.sku} - #{subscription_plan.duration_days} Ngày"
  end
end
