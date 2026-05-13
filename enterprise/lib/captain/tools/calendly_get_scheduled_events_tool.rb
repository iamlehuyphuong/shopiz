# Retrieves upcoming scheduled Calendly events.
class Captain::Tools::CalendlyGetScheduledEventsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::CalendlyClient

  description 'Get upcoming scheduled Calendly appointments. Optionally filter by customer email.'

  param :customer_email, type: 'string', desc: 'Filter events by customer email', required: false
  param :days_ahead, type: 'integer', desc: 'Number of days to look ahead (default 14)', required: false

  def perform(tool_context, customer_email: nil, days_ahead: 14)
    hook = find_calendly_hook(tool_context)
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)
    timezone = hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'

    response = client.scheduled_events(
      user_uri: hook.settings['user_uri'],
      min_start_time: Time.current,
      max_start_time: Time.current + days_ahead.to_i.days
    )
    events = response['collection'] || []

    return 'Không có cuộc hẹn nào trong thời gian tới.' if events.empty?

    # Filter by email if provided
    if customer_email.present?
      events = filter_events_by_email(client, events, customer_email)
      return "Không tìm thấy cuộc hẹn nào cho email #{customer_email}." if events.empty?
    end

    log_tool_usage('get_scheduled_events', count: events.size, email_filter: customer_email)
    format_events(events, timezone)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly error: #{e.message}"
  end

  private

  def filter_events_by_email(client, events, email)
    events.select do |event|
      uuid = event['uri']&.split('/')&.last
      next false unless uuid

      invitees_response = client.event_invitees(event_uuid: uuid)
      invitees = invitees_response['collection'] || []
      invitees.any? { |inv| inv['email']&.downcase == email.downcase }
    end
  end

  def format_events(events, timezone)
    lines = ["Các cuộc hẹn sắp tới (#{events.size}):"]

    events.first(10).each do |event|
      name = event['name'] || event.dig('event_type', 'name') || 'N/A'
      start_time = event['start_time'] ? format_time_local(event['start_time'], timezone) : 'N/A'
      status = event['status']

      lines << "- #{name} | #{start_time} | #{status}"
    end

    lines << "... và #{events.size - 10} cuộc hẹn khác" if events.size > 10
    lines.join("\n")
  end
end
