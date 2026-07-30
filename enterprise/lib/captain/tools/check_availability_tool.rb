module Captain
  module Tools
    class CheckAvailabilityTool < BasePublicTool
      include Captain::Tools::Concerns::BookingRoutable

      description 'Check availability for booking a meeting. Returns a list of available time slots.'

      param :event_type_name, type: 'string', desc: 'Name or keyword of the event type/service (e.g. "Tư vấn", "Demo"). Required for Calendly.',
                              required: false
      param :date, type: 'string', desc: 'The date to check availability for, in YYYY-MM-DD format (e.g., 2026-07-15)', required: false
      param :days, type: 'integer', desc: 'Number of days to check from the date. Default is 1.', required: false

      def perform(tool_context, event_type_name: nil, date: nil, days: 1)
        conversation = find_conversation(tool_context.state)
        return 'Conversation not found' unless conversation

        account = conversation.account
        start_date = date.present? ? Date.parse(date) : Date.current
        end_date = start_date + (days.to_i || 1).days

        # Route to booking platform if configured
        platform = resolve_booking_platform(tool_context)
        if platform == 'calendly'
          # calendly_get_available_times requires event_type_name
          # CheckAvailabilityTool does not have event_type_name param, but the wrapper can ask the AI to provide it
          # via args or we can assume the tool context handles it.
          # Actually, if we use Calendly, we should just let the tool handle the error if event_type_name is missing.
          # Or better, we can just pass the kwargs we have. But calendly requires event_type_name.
          # We might need to adjust the params if Calendly is used, or let the AI know it needs to use calendly directly if we can't map params well.
          # For a generic wrapper, we might just pass the params and hope they align, or we need to add `event_type_name` to the generic tool.
          # Wait, calendly_get_available_times requires event_type_name!
          # Let's add event_type_name to CheckAvailabilityTool just in case, but keep it optional for backward compatibility.
          return delegate_to_calendly_tool(tool_context, event_type_name: event_type_name || 'unknown', preferred_date: date, days_ahead: days)
        end

        # Route to Google Calendar if configured
        config = account.booking_configurations.find_by(is_active: true)
        if config
          fetcher = CalendarService::AvailabilityFetcher.new(config)
          slots = fetcher.fetch(start_date.beginning_of_day, end_date.end_of_day)

          return 'No available slots found for the requested dates.' if slots.empty?

          formatted_slots = slots.map do |slot|
            "#{slot[:start].strftime('%Y-%m-%d %H:%M')} to #{slot[:end].strftime('%H:%M')}"
          end.join("\n")

          return "Available slots:\n#{formatted_slots}"
        end

        # Handle Calendly routing if implemented here later
        # (Assuming Calendly does not have an easy free-slots API, we might just return the link)
        'No calendar integration configured. Please ask the user to wait or send them the booking link.'
      rescue StandardError => e
        ChatwootExceptionTracker.new(e).capture_exception
        'Failed to check availability'
      end

      private

      def calendly_tool_class
        'Captain::Tools::CalendlyGetAvailableTimesTool'
      end
    end
  end
end
