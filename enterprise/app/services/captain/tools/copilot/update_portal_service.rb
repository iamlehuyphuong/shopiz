class Captain::Tools::Copilot::UpdatePortalService < Captain::Tools::BaseTool
  def self.name
    'update_portal'
  end

  description 'Update an existing help center portal configuration'
  param :portal_slug, type: :string, desc: 'Slug of the portal to update', required: true
  param :name, type: :string, desc: 'New name for the portal', required: false
  param :color, type: :string, desc: 'New brand color in hex format (e.g. #1f93ff)', required: false
  param :header_text, type: :string, desc: 'New header/subtitle text', required: false
  param :homepage_link, type: :string, desc: 'New homepage link', required: false
  param :archived, type: :boolean, desc: 'Set to true to archive the portal, false to unarchive', required: false

  def execute(**params)
    portal = Portal.find_by(slug: params[:portal_slug], account_id: @assistant.account_id)
    return 'Portal not found' if portal.nil?

    update_params = build_update_params(params)
    return 'No fields to update. Provide at least one field to change.' if update_params.empty?

    portal.update!(update_params)
    format_response(portal)
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update portal: #{e.message}"
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def build_update_params(params)
    result = {}
    %i[name color header_text homepage_link].each do |key|
      result[key] = params[key] if params[key].present?
    end
    result[:archived] = params[:archived] unless params[:archived].nil?
    result
  end

  def format_response(portal)
    <<~RESPONSE
      Portal updated successfully!
      Portal ID: #{portal.id}
      Name: #{portal.name}
      Slug: #{portal.slug}
      Color: #{portal.color}
      Archived: #{portal.archived}
    RESPONSE
  end
end
