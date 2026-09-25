# Copilot tool: General Manage Booking router
class Captain::Tools::Copilot::ManageMeetingService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'manage_meeting'
  end

  description 'Cancel or reschedule an existing meeting'

  param :action, type: :string, desc: "Action to perform: 'cancel' or 'reschedule'", required: true
  param :start_time, type: :string, desc: 'Original start time of the meeting (e.g. 2025-01-15T07:00:00Z)', required: true
  param :new_start_time, type: :string, desc: "New start time. Required if action is 'reschedule'", required: false
  param :customer_email, type: :string, desc: 'Customer email', required: false
  param :reason, type: :string, desc: 'Reason for cancellation or rescheduling', required: false
  param :timezone, type: :string, desc: 'IANA timezone', required: false

  def execute(action:, start_time:, new_start_time: nil, customer_email: nil, reason: nil, timezone: nil)
    # Route to booking platform if configured
    platform = resolve_booking_platform
    if platform
      args = {
        action: action,
        start_time: start_time,
        new_start_time: new_start_time,
        customer_email: customer_email,
        reason: reason,
        timezone: timezone
      }.compact

      result = delegate_to_booking_tool(**args)
      return result if result
    end

    # Fallback to local Shopiz Google Calendar Integration
    parsed_start = Time.zone.parse(start_time)
    return 'Invalid start time format' unless parsed_start

    booking = @conversation.bookings.find_by(start_time: parsed_start)
    return 'No meeting found at the specified time.' unless booking

    manager = CalendarService::EventManager.new(@conversation.account)

    if action == 'cancel'
      if booking.provider == 'google' && booking.google_event_id
        success = manager.delete_event(booking.google_event_id)
        return 'Failed to cancel meeting on Google Calendar' unless success
      end

      booking.update!(status: :cancelled)
      "Meeting at #{start_time} successfully cancelled."
    elsif action == 'reschedule'
      return 'new_start_time is required for rescheduling' if new_start_time.blank?

      parsed_new = Time.zone.parse(new_start_time)
      return 'Invalid new start time format' unless parsed_new

      if booking.provider == 'google' && booking.google_event_id
        # Simple reschedule: delete old and create new
        manager.delete_event(booking.google_event_id)

        config = @conversation.account.booking_configurations.find_by(is_active: true)
        duration = config&.meeting_duration || 30
        parsed_end = parsed_new + duration.minutes

        event_id = manager.create_event(
          start_time: parsed_new,
          end_time: parsed_end,
          guest_email: booking.guest_email,
          guest_name: booking.guest_name,
          description: reason || 'Rescheduled via Copilot'
        )

        return 'Failed to reschedule meeting on Google Calendar' unless event_id

        booking.update!(start_time: parsed_new, end_time: parsed_end, google_event_id: event_id)
      else
        duration = booking.end_time - booking.start_time
        booking.update!(start_time: parsed_new, end_time: parsed_new + duration)
      end

      "Meeting successfully rescheduled to #{new_start_time}."
    else
      "Invalid action: #{action}. Must be 'cancel' or 'reschedule'"
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to manage meeting'
  end

  private

  def booking_platform_tools
    { 'calendly' => 'Captain::Tools::Copilot::Calendly::ManageBookingService' }.freeze
  end
end
