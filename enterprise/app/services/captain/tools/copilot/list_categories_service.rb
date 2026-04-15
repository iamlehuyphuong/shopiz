class Captain::Tools::Copilot::ListCategoriesService < Captain::Tools::BaseTool
  def self.name
    'list_categories'
  end

  description 'List all categories in a help center portal, optionally filtered by locale'
  param :portal_slug, type: :string, desc: 'Slug of the portal to list categories from', required: true
  param :locale, type: :string, desc: 'Filter categories by locale code (e.g. en, vi)', required: false

  def execute(portal_slug:, locale: nil)
    portal = Portal.find_by(slug: portal_slug, account_id: @assistant.account_id)
    return 'Portal not found' if portal.nil?

    categories = portal.categories.order(:position)
    categories = categories.search_by_locale(locale) if locale.present?

    return "No categories found in portal '#{portal.name}'" unless categories.exists?

    <<~RESPONSE
      Portal: #{portal.name} (#{portal.slug})
      Total categories: #{categories.count}
      #{categories.map { |c| format_category(c) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def format_category(category)
    <<~CATEGORY
      Category ID: #{category.id}
      Name: #{category.name}
      Slug: #{category.slug}
      Locale: #{category.locale}
      Description: #{category.description || 'N/A'}
      Icon: #{category.icon.presence || 'N/A'}
      Position: #{category.position || 'N/A'}
      Articles Count: #{category.articles.count}
      Parent Category ID: #{category.parent_category_id || 'N/A'}
    CATEGORY
  end
end
