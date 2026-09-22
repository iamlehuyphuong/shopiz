# Checks available time slots on Calendly for a specific event type.
class Captain::Tools::Calendly::GetAvailableTimesTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Calendly::Client

  description 'Get available time slots from Calendly for a specific appointment type. ' \
              'IMPORTANT: You MUST use calendly_list_event_types first to get the EXACT event_type_name. ' \
              'NEVER hallucinate or translate the event name. ' \
              'If the specific time the user requested is NOT in the returned slots, DO NOT retry this tool. ' \
              'Immediately tell the user it is unavailable. ' \
              'CRITICAL: If the user requested a specific time of day (e.g. afternoon/buổi chiều), you MUST strictly filter the returned list and ONLY present the slots that match their request.'

  param :event_type_name, type: 'string', desc: 'Name or keyword of the event type (e.g. "Tư vấn", "Demo")', required: true
  param :preferred_date, type: 'string', desc: 'Preferred date in YYYY-MM-DD format', required: false
  param :days_ahead, type: 'integer', desc: 'Number of days to look ahead from preferred_date (max 7)', required: false

  def perform(tool_context, event_type_name:, preferred_date: nil, days_ahead: 7)
    # Anti-loop measure
    cache_key = "calendly_times_#{event_type_name}_#{preferred_date}_#{days_ahead}"
    tool_context.state[:calendly_calls] ||= {}
    if tool_context.state[:calendly_calls][cache_key]
      return 'ERROR: You have already executed this tool with these exact parameters. DO NOT retry. The requested time is NOT available. Stop immediately and inform the user.'
    end

    tool_context.state[:calendly_calls][cache_key] = true

    hook = find_calendly_hook(tool_context)
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)

    # 1. Find the matching event type
    event_type = find_event_type_by_name(client, hook, event_type_name)
    return "Không tìm thấy dịch vụ '#{event_type_name}' trên Calendly." unless event_type

    # 2. Build time range (max 7 days per Calendly API constraint)
    parsed_time = preferred_date.present? ? Time.zone.parse("#{preferred_date}T00:00:00") : Time.current
    start_time = [parsed_time, 1.minute.from_now].max

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
    "Calendly error: #{e.message} - #{e.body}"
  end

  private

  def format_available_times(slots, event_type, timezone)
    grouped = slots.group_by do |slot|
      time = Time.zone.parse(slot['start_time'])
      tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
      time.in_time_zone(tz).strftime('%A, %d/%m/%Y')
    end

    lines = ["Các khung giờ trống cho #{event_type['name']} (#{event_type['duration']} phút):"]

    grouped.each do |date, day_slots|
      time_list = day_slots.map do |slot|
        time = Time.zone.parse(slot['start_time'])
        tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
        time.in_time_zone(tz).strftime('%H:%M')
      end
      lines << "📅 #{date}: #{time_list.join(', ')}"
    end

    lines.join("\n")
  end
end
