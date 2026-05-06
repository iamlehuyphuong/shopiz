class Captain::Tools::Copilot::ListPortalsService < Captain::Tools::BaseTool
  def self.name
    'list_portals'
  end

  description 'List all help center portals in the account with their configuration and article counts'

  def execute
    portals = Portal.where(account_id: @assistant.account_id).order(:name)
    return 'No portals found' unless portals.exists?

    <<~RESPONSE
      Total portals: #{portals.count}
      #{portals.map { |p| format_portal(p) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def format_portal(portal)
    <<~PORTAL
      Portal ID: #{portal.id}
      Name: #{portal.name}
      Slug: #{portal.slug}
      Custom Domain: #{portal.custom_domain || 'N/A'}
      Color: #{portal.color}
      Default Locale: #{portal.default_locale}
      Allowed Locales: #{portal.allowed_locale_codes.join(', ')}
      Header Text: #{portal.header_text || 'N/A'}
      Homepage Link: #{portal.homepage_link || 'N/A'}
      Archived: #{portal.archived}
      Total Articles: #{portal.articles.count}
      Total Categories: #{portal.categories.count}
    PORTAL
  end
end
