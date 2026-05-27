# Copilot tool: Books a Calendly appointment on behalf of the customer.
class Captain::Tools::Copilot::CalendlyBookAppointmentService < Captain::Tools::BaseTool
  def self.name
    'calendly_book_appointment'
  end

  description 'Book a Calendly appointment for the customer. Requires event type, time, name, and email.'

  param :event_type_name, type: :string, desc: 'Name or keyword of the event type to book', required: true
  param :start_time, type: :string, desc: 'Selected time slot in UTC ISO-8601 format (e.g. 2025-01-15T07:00:00Z)', required: true
  param :customer_name, type: :string, desc: 'Customer full name', required: true
  param :customer_email, type: :string, desc: 'Customer email address', required: true
  param :timezone, type: :string, desc: 'IANA timezone (e.g. Asia/Ho_Chi_Minh)', required: false

  def execute(event_type_name:, start_time:, customer_name:, customer_email:, timezone: nil)
    hook = find_calendly_hook
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)
    tz = timezone || hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'

    event_type = find_event_type_by_name(client, hook, event_type_name)
    return "Could not find service '#{event_type_name}' on Calendly." unless event_type

    response = client.create_invitee(
      event_type_uri: event_type['uri'],
      start_time: start_time,
      invitee: { name: customer_name, email: customer_email, timezone: tz }
    )

    resource = response['resource']
    format_booking_confirmation(resource, event_type, tz)
  rescue Calendly::ApiClient::ApiError => e
    handle_booking_error(e, event_type_name)
  end

  def active?
    @user.present? && find_calendly_hook.present?
  end

  private

  include Captain::Tools::Copilot::Concerns::CalendlyHelper

  def handle_booking_error(error, event_type_name)
    case error.status
    when 400
      "Cannot book '#{event_type_name}'. API Error (400): #{error.body.to_json}. (Note: start_time must be the exact UTC format returned by calendly_get_available_times)"
    when 403
      'Calendly account needs to be upgraded to a paid plan to use the booking feature.'
    when 429
      'System is rate limited due to too many API calls. Please try again in 1-2 minutes.'
    else
      "Error when booking: #{error.message} - #{error.body.to_json}"
    end
  end
end
