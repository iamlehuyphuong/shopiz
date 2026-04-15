class Captain::Tools::Copilot::UpdateCategoryService < Captain::Tools::BaseTool
  def self.name
    'update_category'
  end

  description 'Update an existing category in a help center portal'
  param :portal_slug, type: :string, desc: 'Slug of the portal containing the category', required: true
  param :category_id, type: :integer, desc: 'ID of the category to update', required: true
  param :name, type: :string, desc: 'New name for the category', required: false
  param :description, type: :string, desc: 'New description for the category', required: false
  param :icon, type: :string, desc: 'New icon for the category', required: false
  param :locale, type: :string, desc: 'New locale code. Must be in portal allowed locales', required: false

  def execute(**params)
    portal = Portal.find_by(slug: params[:portal_slug], account_id: @assistant.account_id)
    return 'Portal not found' if portal.nil?

    category = portal.categories.find_by(id: params[:category_id])
    return 'Category not found' if category.nil?

    update_params = build_update_params(params)
    return 'No fields to update. Provide at least one field to change.' if update_params.empty?

    category.update!(update_params)
    format_response(category)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update category: #{e.message}"
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def build_update_params(params)
    result = {}
    %i[name description icon locale].each do |key|
      result[key] = params[key] if params[key].present?
    end
    result
  end

  def format_response(category)
    <<~RESPONSE
      Category updated successfully!
      Category ID: #{category.id}
      Name: #{category.name}
      Slug: #{category.slug}
      Locale: #{category.locale}
      Description: #{category.description || 'N/A'}
    RESPONSE
  end
end
