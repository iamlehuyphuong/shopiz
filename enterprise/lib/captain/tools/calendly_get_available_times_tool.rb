# Checks available time slots on Calendly for a specific event type.
class Captain::Tools::CalendlyGetAvailableTimesTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::CalendlyClient

  description 'Get available time slots from Calendly for a specific appointment type. ' \
              'Use after identifying the event type the customer wants. Max 7 days per query.'

  param :event_type_name, type: 'string', desc: 'Name or keyword of the event type (e.g. "Tư vấn", "Demo")', required: true
  param :preferred_date, type: 'string', desc: 'Preferred date in YYYY-MM-DD format', required: false
  param :days_ahead, type: 'integer', desc: 'Number of days to look ahead from preferred_date (max 7)', required: false

  def perform(tool_context, event_type_name:, preferred_date: nil, days_ahead: 7)
    hook = find_calendly_hook(tool_context)
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)

    # 1. Find the matching event type
    event_type = find_event_type_by_name(client, hook, event_type_name)
    return "Không tìm thấy dịch vụ '#{event_type_name}' trên Calendly." unless event_type

    # 2. Build time range (max 7 days per Calendly API constraint)
    start_time = preferred_date.present? ? Time.parse("#{preferred_date}T00:00:00") : Time.current
    capped_days = [days_ahead.to_i, 7].min
    capped_days = 7 if capped_days <= 0
    end_time = start_time + capped_days.days

    # 3. Query available times
    response = client.available_times(
      event_type_uri: event_type['uri'],
      start_time: start_time,
      end_time: end_time
    )
    slots = response['collection'] || []

    return "Không có khung giờ trống cho '#{event_type['name']}' trong #{capped_days} ngày tới. Hãy thử ngày khác." if slots.empty?

    timezone = hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'
    log_tool_usage('get_available_times', event_type: event_type['name'], slots: slots.size)
    format_available_times(slots, event_type, timezone)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly error: #{e.message}"
  end

  private

  def format_available_times(slots, event_type, timezone)
    grouped = slots.group_by do |slot|
      time = Time.parse(slot['start_time'])
      tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
      time.in_time_zone(tz).strftime('%A, %d/%m/%Y')
    end

    lines = ["Các khung giờ trống cho #{event_type['name']} (#{event_type['duration']} phút):"]

    grouped.each do |date, day_slots|
      time_list = day_slots.map do |slot|
        time = Time.parse(slot['start_time'])
        tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
        time.in_time_zone(tz).strftime('%H:%M')
      end
      lines << "📅 #{date}: #{time_list.join(', ')}"
    end

    lines.join("\n")
  end
end
