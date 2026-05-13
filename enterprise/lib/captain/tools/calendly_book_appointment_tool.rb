# Books a Calendly appointment for the customer via the Scheduling API.
class Captain::Tools::CalendlyBookAppointmentTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::CalendlyClient

  description 'Book a Calendly appointment for the customer. Requires event type name, ' \
              'selected start time, customer name and email. Use after the customer has chosen a time slot.'

  param :event_type_name, type: 'string', desc: 'Name or keyword of the event type to book', required: true
  param :start_time, type: 'string', desc: 'Selected time slot in UTC ISO-8601 format (e.g. 2025-01-15T07:00:00Z)', required: true
  param :customer_name, type: 'string', desc: 'Customer full name', required: true
  param :customer_email, type: 'string', desc: 'Customer email address', required: true
  param :timezone, type: 'string', desc: 'IANA timezone (e.g. Asia/Ho_Chi_Minh)', required: false

  def perform(tool_context, event_type_name:, start_time:, customer_name:, customer_email:, timezone: nil)
    hook = find_calendly_hook(tool_context)
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)
    tz = timezone || hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'

    # 1. Resolve event type
    event_type = find_event_type_by_name(client, hook, event_type_name)
    return "Không tìm thấy dịch vụ '#{event_type_name}' trên Calendly." unless event_type

    # 2. Book via Scheduling API
    response = client.create_invitee(
      event_type_uri: event_type['uri'],
      start_time: start_time,
      invitee: {
        name: customer_name,
        email: customer_email,
        timezone: tz
      }
    )

    resource = response['resource']
    log_tool_usage('book_appointment', event_type: event_type['name'], email: customer_email)
    format_booking_confirmation(resource, event_type, tz)
  rescue Calendly::ApiClient::ApiError => e
    handle_booking_error(e, event_type_name)
  end

  private

  def format_booking_confirmation(invitee, event_type, timezone)
    start = format_time_local(invitee['start_time'], timezone) if invitee['start_time']
    reschedule_url = invitee['reschedule_url']
    cancel_url = invitee['cancel_url']

    lines = [
      "✅ Đặt lịch thành công!",
      "📋 Dịch vụ: #{event_type['name']}",
      "📅 Thời gian: #{start}",
      "👤 Khách: #{invitee.dig('invitee', 'name') || invitee['name']}",
      "📧 Email: #{invitee.dig('invitee', 'email') || invitee['email']}"
    ]
    lines << "🔄 Thay đổi lịch: #{reschedule_url}" if reschedule_url
    lines << "❌ Hủy lịch: #{cancel_url}" if cancel_url

    lines.join("\n")
  end

  def handle_booking_error(error, event_type_name)
    case error.status
    when 400
      "Không thể đặt lịch '#{event_type_name}'. Khung giờ này có thể đã được đặt. Hãy chọn khung giờ khác."
    when 403
      "Calendly account cần nâng cấp lên gói trả phí để sử dụng tính năng đặt lịch."
    else
      "Lỗi khi đặt lịch: #{error.message}"
    end
  end
end
