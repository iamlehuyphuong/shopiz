require "administrate/base_dashboard"

class SubscriptionPlanDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account_subscriptions: Field::HasMany,
    accounts: Field::HasMany,
    currency: Field::String,
    description_en: Field::Text,
    description_vi: Field::Text,
    duration_days: Field::Number,
    features: SubscriptionPlanFeaturesField,
    limits: SubscriptionPlanLimitsField,
    name_en: Field::String,
    name_vi: Field::String,
    price_amount: Field::String.with_options(searchable: false),
    sku: Field::String,
    visible: Field::Boolean,
    is_free: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    sku
    name_en
    name_vi
    price_amount
    duration_days
    visible
    is_free
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    sku
    name_en
    name_vi
    description_en
    description_vi
    price_amount
    currency
    duration_days
    limits
    features
    visible
    is_free
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    sku
    name_en
    name_vi
    description_en
    description_vi
    price_amount
    currency
    duration_days
    limits
    features
    visible
    is_free
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how subscription plans are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(subscription_plan)
  #   "SubscriptionPlan ##{subscription_plan.id}"
  # end
end
