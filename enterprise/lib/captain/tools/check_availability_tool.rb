module Captain
  module Tools
    class CheckAvailabilityTool < BasePublicTool
      description 'Check availability for booking a meeting. Returns a list of available time slots.'

      param :date, type: 'string', desc: 'The date to check availability for, in YYYY-MM-DD format (e.g., 2026-07-15)', required: false
      param :days, type: 'integer', desc: 'Number of days to check from the date. Default is 1.', required: false

      def perform(tool_context, date: nil, days: 1)
        conversation = find_conversation(tool_context.state)
        return 'Conversation not found' unless conversation

        account = conversation.account
        start_date = date.present? ? Date.parse(date) : Date.current
        end_date = start_date + (days.to_i || 1).days

        # Route to Google Calendar if configured
        config = account.booking_configurations.find_by(is_active: true)
        if config
          fetcher = CalendarService::AvailabilityFetcher.new(config)
          slots = fetcher.fetch(start_date.beginning_of_day, end_date.end_of_day)

          return "No available slots found for the requested dates." if slots.empty?

          formatted_slots = slots.map do |slot|
            "#{slot[:start].strftime('%Y-%m-%d %H:%M')} to #{slot[:end].strftime('%H:%M')}"
          end.join("\n")

          return "Available slots:\n#{formatted_slots}"
        end

        # Handle Calendly routing if implemented here later
        # (Assuming Calendly does not have an easy free-slots API, we might just return the link)
        "No calendar integration configured. Please ask the user to wait or send them the booking link."
      rescue StandardError => e
        ChatwootExceptionTracker.new(e).capture_exception
        'Failed to check availability'
      end
    end
  end
end
