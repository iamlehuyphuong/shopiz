# Lists available Calendly event types (appointment services) for the connected account.
class Captain::Tools::CalendlyListEventTypesTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::CalendlyClient

  description 'List available Calendly appointment types/services (e.g. Consultation, Demo). ' \
              'Use this when the customer wants to book an appointment but has not specified which service.'

  def perform(tool_context)
    hook = find_calendly_hook(tool_context)
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)
    response = client.event_types(user_uri: hook.settings['user_uri'])
    collection = response['collection'] || []

    return 'No active event types found on Calendly.' if collection.empty?

    log_tool_usage('list_event_types', count: collection.size)
    format_event_types(collection)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly error: #{e.message}"
  end

  private

  def format_event_types(types)
    lines = types.map do |et|
      duration = et['duration'] || 0
      name = et['name']
      desc = et['description_plain'].presence
      line = "- #{name} (#{duration} phút)"
      line += " — #{desc}" if desc
      line
    end

    "Các dịch vụ có sẵn trên Calendly:\n#{lines.join("\n")}\n\nIMPORTANT: When using other Calendly tools, you MUST pass the EXACT service name as listed above. Do not translate it."
  end
end
