class Captain::Tools::ManageMeetingTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::BookingRoutable

  description 'Cancel or reschedule an existing booked meeting'

  param :action, type: 'string', desc: "Action to perform: 'cancel' or 'reschedule'", required: true
  param :start_time, type: 'string', desc: 'The original start time of the meeting (YYYY-MM-DD HH:MM)', required: true
  param :new_start_time, type: 'string', desc: "New start time (YYYY-MM-DD HH:MM). Required if action is 'reschedule'", required: false
  param :guest_email, type: 'string', desc: 'The email address of the guest', required: false
  param :reason, type: 'string', desc: 'Reason for cancellation or rescheduling', required: false

  def perform(tool_context, action:, start_time:, new_start_time: nil, guest_email: nil, reason: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Route to booking platform if configured
    platform = resolve_booking_platform(tool_context)
    if platform == 'calendly'
      return delegate_to_calendly_tool(
        tool_context,
        customer_email: guest_email || conversation.contact&.email || 'unknown',
        action: action
      )
    end

    parsed_start = Time.zone.parse(start_time)
    return 'Invalid start time format' unless parsed_start

    booking = conversation.bookings.find_by(start_time: parsed_start)
    return 'No meeting found at the specified time.' unless booking

    manager = CalendarService::EventManager.new(conversation.account)
    
    if action == 'cancel'
      if booking.provider == 'google' && booking.google_event_id
        success = manager.delete_event(booking.google_event_id)
        return 'Failed to cancel meeting on Google Calendar' unless success
      end

      booking.update!(status: :cancelled)
      log_tool_usage('cancel_meeting', { conversation_id: conversation.id, booking_id: booking.id })
      "Meeting at #{start_time} successfully cancelled."
      
    elsif action == 'reschedule'
      return 'new_start_time is required for rescheduling' if new_start_time.blank?
      parsed_new = Time.zone.parse(new_start_time)
      return 'Invalid new start time format' unless parsed_new

      if booking.provider == 'google' && booking.google_event_id
        manager.delete_event(booking.google_event_id)
        
        config = conversation.account.booking_configurations.find_by(is_active: true)
        duration = config&.meeting_duration || 30
        parsed_end = parsed_new + duration.minutes
        
        event_id = manager.create_event(
          start_time: parsed_new,
          end_time: parsed_end,
          guest_email: booking.guest_email,
          guest_name: booking.guest_name,
          description: reason || "Rescheduled via Agent"
        )
        
        return 'Failed to reschedule meeting on Google Calendar' unless event_id
        booking.update!(start_time: parsed_new, end_time: parsed_end, google_event_id: event_id)
      else
        duration = booking.end_time - booking.start_time
        booking.update!(start_time: parsed_new, end_time: parsed_new + duration)
      end

      log_tool_usage('reschedule_meeting', { conversation_id: conversation.id, booking_id: booking.id })
      "Meeting successfully rescheduled to #{new_start_time}."
    else
      "Invalid action: #{action}. Must be 'cancel' or 'reschedule'"
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to manage meeting'
  end

  private

  def calendly_tool_class
    'Captain::Tools::Calendly::ManageBookingTool'
  end
end
