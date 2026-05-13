# Copilot tool: Gets available Calendly time slots for the agent.
class Captain::Tools::Copilot::CalendlyGetAvailableTimesService < Captain::Tools::BaseTool
  def self.name
    'calendly_get_available_times'
  end

  description 'Get available time slots from Calendly for a specific appointment type. Max 7 days per query.'

  param :event_type_name, type: :string, desc: 'Name or keyword of the event type (e.g. "Tư vấn", "Demo")', required: true
  param :preferred_date, type: :string, desc: 'Preferred date in YYYY-MM-DD format', required: false
  param :days_ahead, type: :integer, desc: 'Number of days to look ahead from preferred_date (max 7)', required: false

  def execute(event_type_name:, preferred_date: nil, days_ahead: 7)
    hook = find_calendly_hook
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)

    event_type = find_event_type_by_name(client, hook, event_type_name)
    return "Không tìm thấy dịch vụ '#{event_type_name}' trên Calendly." unless event_type

    parsed_time = preferred_date.present? ? Time.parse("#{preferred_date}T00:00:00") : Time.current
    start_time = [parsed_time, Time.current + 1.minute].max
    capped_days = [[days_ahead.to_i, 7].min, 1].max
    end_time = start_time + capped_days.days

    response = client.available_times(
      event_type_uri: event_type['uri'],
      start_time: start_time,
      end_time: end_time
    )
    slots = response['collection'] || []

    return "Không có khung giờ trống cho '#{event_type['name']}' trong #{capped_days} ngày tới." if slots.empty?

    timezone = hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'
    format_available_times(slots, event_type, timezone)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly error: #{e.message}"
  end

  def active?
    @user.present? && find_calendly_hook.present?
  end

  private

  include Captain::Tools::Copilot::Concerns::CalendlyHelper
end
