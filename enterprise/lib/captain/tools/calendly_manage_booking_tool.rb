# Provides reschedule or cancel links for an existing Calendly booking.
class Captain::Tools::CalendlyManageBookingTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::CalendlyClient

  description 'Get reschedule or cancel link for an existing Calendly booking. ' \
              'Use when the customer wants to change or cancel their appointment.'

  param :customer_email, type: 'string', desc: 'Email used when booking the appointment', required: true
  param :action, type: 'string', desc: 'Action to perform: "reschedule" or "cancel"', required: true

  def perform(tool_context, customer_email:, action:)
    hook = find_calendly_hook(tool_context)
    return calendly_not_connected_message unless hook

    unless %w[reschedule cancel].include?(action)
      return "Hành động không hợp lệ. Vui lòng chọn 'reschedule' (dời lịch) hoặc 'cancel' (hủy)."
    end

    client = calendly_client(hook)
    timezone = hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'

    # Find the next upcoming event for this email
    invitee = find_upcoming_invitee(client, hook, customer_email)
    return "Không tìm thấy cuộc hẹn sắp tới cho email #{customer_email}." unless invitee

    log_tool_usage('manage_booking', action: action, email: customer_email)
    format_manage_response(invitee, action, timezone)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly error: #{e.message}"
  end

  private

  def find_upcoming_invitee(client, hook, email)
    response = client.scheduled_events(
      user_uri: hook.settings['user_uri'],
      min_start_time: Time.current,
      max_start_time: Time.current + 30.days
    )
    events = response['collection'] || []

    events.each do |event|
      uuid = event['uri']&.split('/')&.last
      next unless uuid

      invitees_response = client.event_invitees(event_uuid: uuid)
      invitees = invitees_response['collection'] || []
      match = invitees.find { |inv| inv['email']&.downcase == email.downcase }

      if match
        return match.merge(
          'event_name' => event['name'],
          'event_start_time' => event['start_time']
        )
      end
    end

    nil
  end

  def format_manage_response(invitee, action, timezone)
    event_name = invitee['event_name'] || 'N/A'
    start_time = invitee['event_start_time'] ? format_time_local(invitee['event_start_time'], timezone) : 'N/A'

    if action == 'reschedule'
      url = invitee['reschedule_url']
      return "Không có link dời lịch cho cuộc hẹn này." unless url

      <<~MSG.strip
        🔄 Dời lịch cuộc hẹn:
        📋 Dịch vụ: #{event_name}
        📅 Lịch hiện tại: #{start_time}
        🔗 Link dời lịch: #{url}
      MSG
    else
      url = invitee['cancel_url']
      return "Không có link hủy lịch cho cuộc hẹn này." unless url

      <<~MSG.strip
        ❌ Hủy cuộc hẹn:
        📋 Dịch vụ: #{event_name}
        📅 Lịch hiện tại: #{start_time}
        🔗 Link hủy: #{url}
      MSG
    end
  end
end
