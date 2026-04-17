require 'administrate/base_dashboard'

class EmailTemplateDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    body: Field::Text,
    locale: Field::String,
    template_type: Field::Select.with_options(searchable: false, collection: %w[layout content]),
    account: Field::BelongsTo.with_options(optional: true),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    locale
    template_type
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    body
    locale
    template_type
    account
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    body
    locale
    template_type
    account
  ].freeze

  # COLLECTION_FILTERS
  COLLECTION_FILTERS = {}.freeze

  def display_resource(email_template)
    email_template.name
  end
end
