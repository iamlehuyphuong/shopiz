require "administrate/base_dashboard"

class SubscriptionPlanDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    subscription_tier: Field::BelongsTo,
    account_subscriptions: Field::HasMany,
    accounts: Field::HasMany,
    currency: Field::String,
    duration_days: Field::Select.with_options(collection: [180, 365, 730]),
    price_amount: Field::String.with_options(searchable: false),
    sku: Field::String,
    visible: Field::Boolean,
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
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    subscription_tier
    sku
    price_amount
    currency
    duration_days
    visible
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
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
