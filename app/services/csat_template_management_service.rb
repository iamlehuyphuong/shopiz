class CsatTemplateManagementService
  DEFAULT_BUTTON_TEXT = 'Please rate us'.freeze
  DEFAULT_LANGUAGE = 'en'.freeze

  def initialize(inbox)
    @inbox = inbox
  end

  def template_status
    template = @inbox.csat_config&.dig('template')
    return { template_exists: false } unless template

    get_whatsapp_template_status(template)
  rescue StandardError => e
    Rails.logger.error "Error fetching CSAT template status: #{e.message}"
    { service_error: e.message }
  end

  def create_template(template_params)
    validate_template_params!(template_params)

    delete_existing_template_if_needed

    result = create_template_via_provider(template_params)
    update_inbox_csat_config(result) if result[:success]

    result
  rescue StandardError => e
    Rails.logger.error "Error creating CSAT template: #{e.message}"
    { success: false, service_error: 'Template creation failed' }
  end

  private

  def validate_template_params!(template_params)
    raise ActionController::ParameterMissing, 'message' if template_params[:message].blank?
  end

  def create_template_via_provider(template_params)
    create_whatsapp_template(template_params)
  end

  def create_whatsapp_template(template_params)
    template_config = build_template_config(template_params)
    Whatsapp::CsatTemplateService.new(@inbox.channel).create_template(template_config)
  end

  def build_template_config(template_params)
    {
      message: template_params[:message],
      button_text: template_params[:button_text] || DEFAULT_BUTTON_TEXT,
      base_url: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'),
      language: template_params[:language] || DEFAULT_LANGUAGE,
      template_name: CsatTemplateNameService.csat_template_name(@inbox.id)
    }
  end

  def update_inbox_csat_config(result)
    current_config = @inbox.csat_config || {}
    template_data = build_template_data_from_result(result)
    updated_config = current_config.merge('template' => template_data)
    @inbox.update!(csat_config: updated_config)
  end

  def build_template_data_from_result(result)
    build_whatsapp_cloud_template_data(result)
  end

  def build_whatsapp_cloud_template_data(result)
    {
      'name' => result[:template_name],
      'template_id' => result[:template_id],
      'language' => result[:language],
      'created_at' => Time.current.iso8601
    }
  end

  def get_whatsapp_template_status(template)
    template_name = template['name'] || CsatTemplateNameService.csat_template_name(@inbox.id)
    status_result = Whatsapp::CsatTemplateService.new(@inbox.channel).get_template_status(template_name)
    return { template_exists: false, error: 'Template not found' } unless status_result.is_a?(Hash)

    if status_result[:success]
      {
        template_exists: true,
        template_name: template_name,
        status: status_result[:template][:status],
        template_id: status_result[:template][:id]
      }
    else
      {
        template_exists: false,
        error: 'Template not found'
      }
    end
  end

  def delete_existing_template_if_needed
    template = @inbox.csat_config&.dig('template')
    return true if template.blank?

    delete_existing_whatsapp_template(template)
  rescue StandardError => e
    Rails.logger.error "Error during template deletion for inbox #{@inbox.id}: #{e.message}"
    false
  end

  def delete_existing_whatsapp_template(template)
    template_name = template['name']
    return true if template_name.blank?

    csat_template_service = Whatsapp::CsatTemplateService.new(@inbox.channel)
    template_status = csat_template_service.get_template_status(template_name)
    return true unless template_status[:success]

    deletion_result = csat_template_service.delete_template(template_name)
    if deletion_result[:success]
      Rails.logger.info "Deleted existing CSAT template '#{template_name}' for inbox #{@inbox.id}"
      true
    else
      Rails.logger.warn "Failed to delete existing CSAT template '#{template_name}' for inbox #{@inbox.id}: #{deletion_result[:response_body]}"
      false
    end
  end
end
