module Captain
  module Tools
    class BookMeetingTool < BasePublicTool
      description 'Book a meeting on the calendar'

      param :start_time, type: 'string', desc: 'The start time of the meeting (YYYY-MM-DD HH:MM)'
      param :guest_email, type: 'string', desc: 'The email address of the guest'
      param :guest_name, type: 'string', desc: 'The name of the guest'
      param :notes, type: 'string', desc: 'Additional notes or context for the meeting', required: false

      def perform(tool_context, start_time:, guest_email:, guest_name:, notes: nil)
        conversation = find_conversation(tool_context.state)
        return 'Conversation not found' unless conversation

        account = conversation.account
        contact = conversation.contact

        config = account.booking_configurations.find_by(is_active: true)
        return "No active calendar integration found." unless config

        parsed_start = Time.zone.parse(start_time)
        return "Invalid start time format" unless parsed_start

        duration = config.meeting_duration || 30
        parsed_end = parsed_start + duration.minutes

        manager = CalendarService::EventManager.new(account)
        event_id = manager.create_event(
          start_time: parsed_start,
          end_time: parsed_end,
          guest_email: guest_email,
          guest_name: guest_name,
          description: notes
        )

        return "Failed to book meeting on the calendar." unless event_id

        # Save booking in database
        account.bookings.create!(
          conversation: conversation,
          contact: contact,
          start_time: parsed_start,
          end_time: parsed_end,
          guest_name: guest_name,
          guest_email: guest_email,
          google_event_id: event_id,
          provider: 'google',
          status: :scheduled # assuming an enum status
        )

        log_tool_usage('book_meeting', { conversation_id: conversation.id, start_time: start_time })

        "Meeting successfully booked for #{guest_name} at #{start_time}."
      rescue StandardError => e
        ChatwootExceptionTracker.new(e).capture_exception
        'Failed to book meeting'
      end
    end
  end
end
