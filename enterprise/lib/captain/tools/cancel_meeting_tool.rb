module Captain
  module Tools
    class CancelMeetingTool < BasePublicTool
      description 'Cancel an existing booked meeting'

      param :start_time, type: 'string', desc: 'The start time of the meeting to cancel (YYYY-MM-DD HH:MM)'

      def perform(tool_context, start_time:)
        conversation = find_conversation(tool_context.state)
        return 'Conversation not found' unless conversation

        parsed_start = Time.zone.parse(start_time)
        return "Invalid start time format" unless parsed_start

        booking = conversation.bookings.find_by(start_time: parsed_start)
        return "No meeting found at the specified time." unless booking

        manager = CalendarService::EventManager.new(conversation.account)
        if booking.provider == 'google' && booking.google_event_id
          success = manager.delete_event(booking.google_event_id)
          return "Failed to cancel meeting on Google Calendar" unless success
        end

        booking.update!(status: :cancelled)
        
        log_tool_usage('cancel_meeting', { conversation_id: conversation.id, booking_id: booking.id })
        
        "Meeting at #{start_time} successfully cancelled."
      rescue StandardError => e
        ChatwootExceptionTracker.new(e).capture_exception
        'Failed to cancel meeting'
      end
    end
  end
end
