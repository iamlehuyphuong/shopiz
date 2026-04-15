class Captain::Tools::Copilot::CreateCategoryService < Captain::Tools::BaseTool
  def self.name
    'create_category'
  end

  description 'Create a new category in a help center portal'
  param :portal_slug, type: :string, desc: 'Slug of the portal to create the category in', required: true
  param :name, type: :string, desc: 'Name of the category', required: true
  param :locale, type: :string, desc: 'Locale code for the category (e.g. en, vi). Must be in portal allowed locales', required: true
  param :description, type: :string, desc: 'Description of the category', required: false
  param :icon, type: :string, desc: 'Icon for the category (emoji or icon name)', required: false
  param :parent_category_id, type: :integer, desc: 'ID of the parent category for sub-categories', required: false

  def execute(**params)
    portal = Portal.find_by(slug: params[:portal_slug], account_id: @assistant.account_id)
    return 'Portal not found' if portal.nil?

    category = portal.categories.create!(build_category_params(params))

    <<~RESPONSE
      Category created successfully!
      Category ID: #{category.id}
      Name: #{category.name}
      Slug: #{category.slug}
      Locale: #{category.locale}
      Description: #{category.description || 'N/A'}
    RESPONSE
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create category: #{e.message}"
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def build_category_params(params)
    result = { name: params[:name], locale: params[:locale], slug: params[:name].parameterize(separator: '-') }
    result[:description] = params[:description] if params[:description].present?
    result[:icon] = params[:icon] if params[:icon].present?
    result[:parent_category_id] = params[:parent_category_id] if params[:parent_category_id].present?
    result
  end
end
