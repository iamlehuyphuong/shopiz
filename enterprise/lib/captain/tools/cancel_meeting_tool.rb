module Captain
  module Tools
    class CancelMeetingTool < BasePublicTool
      include Captain::Tools::Concerns::BookingRoutable

      description 'Cancel an existing booked meeting'

      param :start_time, type: 'string', desc: 'The start time of the meeting to cancel (YYYY-MM-DD HH:MM)', required: false
      param :guest_email, type: 'string', desc: 'The email address of the guest. Required for Calendly.', required: false

      def perform(tool_context, start_time: nil, guest_email: nil)
        conversation = find_conversation(tool_context.state)
        return 'Conversation not found' unless conversation

        # Route to booking platform if configured
        platform = resolve_booking_platform(tool_context)
        if platform == 'calendly'
          return delegate_to_calendly_tool(
            tool_context,
            customer_email: guest_email || conversation.contact&.email || 'unknown',
            action: 'cancel'
          )
        end

        return 'start_time is required for Google Calendar' unless start_time.present?

        parsed_start = Time.zone.parse(start_time)
        return 'Invalid start time format' unless parsed_start

        booking = conversation.bookings.find_by(start_time: parsed_start)
        return 'No meeting found at the specified time.' unless booking

        manager = CalendarService::EventManager.new(conversation.account)
        if booking.provider == 'google' && booking.google_event_id
          success = manager.delete_event(booking.google_event_id)
          return 'Failed to cancel meeting on Google Calendar' unless success
        end

        booking.update!(status: :cancelled)

        log_tool_usage('cancel_meeting', { conversation_id: conversation.id, booking_id: booking.id })

        "Meeting at #{start_time} successfully cancelled."
      rescue StandardError => e
        ChatwootExceptionTracker.new(e).capture_exception
        'Failed to cancel meeting'
      end

      private

      def calendly_tool_class
        'Captain::Tools::CalendlyManageBookingTool'
      end
    end
  end
end
