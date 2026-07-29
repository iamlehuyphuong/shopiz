# Copilot tool: Lists available Calendly event types for the agent.
class Captain::Tools::Copilot::CalendlyListEventTypesService < Captain::Tools::BaseTool
  def self.name
    'calendly_list_event_types'
  end

  description 'List available Calendly appointment types/services (e.g. Consultation, Demo)'

  def execute
    hook = find_calendly_hook
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)
    response = client.event_types(user_uri: hook.settings['user_uri'])
    collection = response['collection'] || []

    return 'No active event types found on Calendly.' if collection.empty?

    format_event_types(collection)
  rescue Calendly::ApiClient::ApiError => e
    "Lỗi API Calendly: #{e.message} - #{e.body.to_json}"
  rescue StandardError => e
    "Lỗi hệ thống khi gọi Calendly: #{e.message}"
  end

  def active?
    @user.present? && find_calendly_hook.present?
  end

  include Captain::Tools::Copilot::Concerns::CalendlyHelper
end
