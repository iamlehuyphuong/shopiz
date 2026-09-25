module CalendarService
  class AvailabilityFetcher
    require 'google/apis/calendar_v3'

    def initialize(booking_configuration)
      @config = booking_configuration
      @integration = @config.account.calendar_integrations.find_by(provider: 'google')
    end

    def fetch(start_time, end_time)
      return [] unless @integration && @config.is_active

      # Refresh token if needed
      GoogleAuth.new(@integration).refresh_token!

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @integration.access_token

      freebusy_request = Google::Apis::CalendarV3::FreeBusyRequest.new(
        time_min: start_time.utc.iso8601,
        time_max: end_time.utc.iso8601,
        items: [{ id: 'primary' }]
      )

      freebusy_response = service.query_freebusy(freebusy_request)
      busy_periods = freebusy_response.calendars['primary'].busy || []

      # Compute slots
      compute_available_slots(start_time, end_time, busy_periods)
    end

    private

    def compute_available_slots(start_date, end_date, busy_periods)
      available_slots = []
      current_date = start_date.to_date

      while current_date <= end_date.to_date
        working_hour = @config.booking_working_hours.find_by(day_of_week: current_date.wday)
        if working_hour && !working_hour.closed_all_day
          open_time = current_date.in_time_zone.change(hour: working_hour.open_hour, min: working_hour.open_minutes)
          close_time = current_date.in_time_zone.change(hour: working_hour.close_hour, min: working_hour.close_minutes)

          # Open all day override
          if working_hour.open_all_day
            open_time = current_date.in_time_zone.beginning_of_day
            close_time = current_date.in_time_zone.end_of_day
          end

          slot_start = open_time
          duration = @config.meeting_duration || 30
          buffer = @config.buffer_time || 0

          while slot_start + duration.minutes <= close_time
            slot_end = slot_start + duration.minutes

            # Check against busy periods
            is_busy = busy_periods.any? do |busy|
              busy_start = busy.start.in_time_zone
              busy_end = busy.end.in_time_zone
              # Overlap condition: slot_start < busy_end AND slot_end > busy_start
              slot_start < busy_end && slot_end > busy_start
            end

            available_slots << { start: slot_start, end: slot_end } unless is_busy

            slot_start = slot_end + buffer.minutes
          end
        end

        current_date += 1.day
      end

      available_slots
    end
  end
end
