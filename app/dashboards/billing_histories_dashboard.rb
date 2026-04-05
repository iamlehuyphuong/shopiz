require 'administrate/base_dashboard'

class BillingHistoriesDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    product_id: Field::String,
    product_name: Field::String,
    sku: Field::String,
    status: Field::Select.with_options(
      collection: BillingHistories.statuses.keys.map { |s| [s.humanize, s] }
    ),
    price_amount: Field::Number,
    price_currency: Field::String,
    transaction_id: Field::String,
    metadata: Field::String.with_options(searchable: false), # Displaying as string for now
    description: Field::String,
    transaction_date_time: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  COLLECTION_ATTRIBUTES = %i[
    id
    account
    product_name
    price_amount
    price_currency
    status
    created_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    product_id
    product_name
    sku
    status
    price_amount
    price_currency
    transaction_id
    metadata
    description
    transaction_date_time
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    account
    product_id
    product_name
    sku
    status
    price_amount
    price_currency
    transaction_id
    metadata
    description
    transaction_date_time
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how billing histories are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(billing_history)
    "Billing History ##{billing_history.id}"
  end
end
