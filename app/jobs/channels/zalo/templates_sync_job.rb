class Channels::Zalo::TemplatesSyncJob < ApplicationJob
  queue_as :default

  def perform(channel)
    response = channel.client.get_templates
    return unless response && response['error'] == 0 && response['data']

    templates = response.dig('data', 'data') || response['data'] || []

    templates.each do |template_data|
      # ZNS Template API structure mapping
      template_name = template_data['templateName'] || template_data['template_name']
      status_str = template_data['status']&.downcase || 'active'
      
      # Determine ZaloTemplate status
      status = if status_str == 'approved' || status_str == 'active'
                 :active
               else
                 :draft
               end

      # Zalo message templates using ZaloMessageTemplate model
      zalo_template = channel.zalo_message_templates.find_or_initialize_by(
        account_id: channel.account_id,
        template_name: template_name
      )

      # Sample content if not deeply parsed
      content = template_data['listParams'] || {}

      zalo_template.assign_attributes(
        status: status,
        language: 'VI',
        template_content: { params: content, raw: template_data }
      )
      
      zalo_template.save!
    end
  end
end
