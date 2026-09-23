# Copilot tool: General Book Meeting router
class Captain::Tools::Copilot::BookMeetingService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'book_meeting'
  end

  description 'Book a meeting/appointment for the customer. Routes to Calendly or Google Calendar.'

  param :event_type_name, type: :string, desc: 'Name or keyword of the event type to book', required: true
  param :start_time, type: :string, desc: 'Selected time slot in UTC ISO-8601 format (e.g. 2025-01-15T07:00:00Z)', required: true
  param :customer_name, type: :string, desc: 'Customer full name', required: false
  param :customer_email, type: :string, desc: 'Customer email address', required: false
  param :timezone, type: :string, desc: 'IANA timezone (e.g. Asia/Ho_Chi_Minh)', required: false

  def execute(event_type_name:, start_time:, customer_name: nil, customer_email: nil, timezone: nil)
    # Route to booking platform if configured
    platform = resolve_booking_platform
    if platform
      args = {
        event_type_name: event_type_name,
        start_time: start_time,
        customer_name: customer_name,
        customer_email: customer_email,
        timezone: timezone
      }.compact
      
      result = delegate_to_booking_tool(**args)
      return result if result
    end

    # Fallback to local Shopiz Google Calendar Integration
    config = @conversation.account.booking_configurations.find_by(is_active: true)
    return 'No active calendar integration found.' unless config

    parsed_start = Time.zone.parse(start_time)
    return 'Invalid start time format' unless parsed_start

    duration = config.meeting_duration || 30
    parsed_end = parsed_start + duration.minutes

    manager = CalendarService::EventManager.new(@conversation.account)
    event_id = manager.create_event(
      start_time: parsed_start,
      end_time: parsed_end,
      guest_email: customer_email || @conversation.contact&.email,
      guest_name: customer_name || @conversation.contact&.name,
      description: "Booked via Copilot"
    )

    return 'Failed to book meeting on the calendar.' unless event_id

    # Save booking in database
    @conversation.account.bookings.create!(
      conversation: @conversation,
      contact: @conversation.contact,
      start_time: parsed_start,
      end_time: parsed_end,
      guest_name: customer_name || @conversation.contact&.name,
      guest_email: customer_email || @conversation.contact&.email,
      google_event_id: event_id,
      provider: 'google',
      status: :scheduled
    )

    "Meeting successfully booked for #{customer_name || @conversation.contact&.name} at #{start_time}."
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to book meeting'
  end

  private

  def booking_platform_tools
    { 'calendly' => 'Captain::Tools::Copilot::Calendly::BookAppointmentService' }.freeze
  end
end
