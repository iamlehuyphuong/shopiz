module CalendarService
  class EventManager
    require 'google/apis/calendar_v3'

    def initialize(account)
      @account = account
      @integration = @account.calendar_integrations.find_by(provider: 'google')
    end

    def create_event(start_time:, end_time:, guest_email:, guest_name:, summary: nil, description: nil)
      return nil unless @integration

      GoogleAuth.new(@integration).refresh_token!

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @integration.access_token

      event = Google::Apis::CalendarV3::Event.new(
        summary: summary || "Meeting with #{guest_name}",
        description: description,
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: start_time.utc.iso8601
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: end_time.utc.iso8601
        ),
        attendees: [
          Google::Apis::CalendarV3::EventAttendee.new(email: guest_email)
        ]
      )

      result = service.insert_event('primary', event, send_updates: 'all')
      result.id
    rescue StandardError => e
      Rails.logger.error("Failed to create Google Calendar event: #{e.message}")
      nil
    end

    def delete_event(event_id)
      return false unless @integration

      GoogleAuth.new(@integration).refresh_token!

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @integration.access_token

      service.delete_event('primary', event_id, send_updates: 'all')
      true
    rescue StandardError => e
      Rails.logger.error("Failed to delete Google Calendar event: #{e.message}")
      false
    end
  end
end
