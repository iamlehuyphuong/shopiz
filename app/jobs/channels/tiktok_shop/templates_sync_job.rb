class Channels::TiktokShop::TemplatesSyncJob < ApplicationJob
  queue_as :default

  def perform(channel)
    response = channel.client.get_message_templates
    return unless response && response['code'] == 0 && response['data']

    templates = response.dig('data', 'templates') || response['data'] || []

    templates.each do |template_data|
      template_id = template_data['template_id'] || template_data['id']
      template_name = template_data['name'] || "TiktokShop Template #{template_id}"
      status_str = template_data['status']&.downcase || 'active'

      # Determine MessageTemplate status
      status = if status_str == 'approved' || status_str == 'active'
                 :approved
               else
                 :draft
               end

      # Reuse MessageTemplate class normally used by whatsapp
      message_template = channel.account.message_templates.find_or_initialize_by(
        inbox_id: channel.inbox.id,
        name: template_name,
        channel_type: 'Channel::TiktokShop'
      )

      message_template.assign_attributes(
        status: status,
        language: template_data['language'] || 'vi',
        platform_template_id: template_id,
        content: template_data
      )

      message_template.save!
    end
  end
end
