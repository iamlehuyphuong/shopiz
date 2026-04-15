class Captain::Tools::Copilot::CreatePortalService < Captain::Tools::BaseTool
  def self.name
    'create_portal'
  end

  description 'Create a new help center portal'
  param :name, type: :string, desc: 'Name of the portal', required: true
  param :slug, type: :string, desc: 'URL slug for the portal (must be unique, lowercase, no spaces)', required: true
  param :color, type: :string, desc: 'Brand color for the portal in hex format (e.g. #1f93ff)', required: false
  param :header_text, type: :string, desc: 'Header/subtitle text displayed on the portal', required: false
  param :homepage_link, type: :string, desc: 'Link to the homepage/website', required: false
  param :default_locale, type: :string, desc: 'Default locale code (e.g. en, vi). Defaults to en', required: false

  def execute(**params)
    portal_params = build_portal_params(params)
    portal = Portal.create!(portal_params.merge(account_id: @assistant.account_id))

    <<~RESPONSE
      Portal created successfully!
      Portal ID: #{portal.id}
      Name: #{portal.name}
      Slug: #{portal.slug}
      Color: #{portal.color}
      Default Locale: #{portal.default_locale}
    RESPONSE
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create portal: #{e.message}"
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def build_portal_params(params)
    locale = params[:default_locale] || 'en'
    result = { name: params[:name], slug: params[:slug], config: { default_locale: locale, allowed_locales: [locale] } }
    result[:color] = params[:color] if params[:color].present?
    result[:header_text] = params[:header_text] if params[:header_text].present?
    result[:homepage_link] = params[:homepage_link] if params[:homepage_link].present?
    result
  end
end
