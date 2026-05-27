# Shared helpers for Calendly copilot tools.
# Provides hook lookup, API client, event type matching, and formatting.
module Captain::Tools::Copilot::Concerns::CalendlyHelper
  extend ActiveSupport::Concern

  private

  def find_calendly_hook
    return nil unless @assistant

    @assistant.account.hooks.find_by(app_id: 'calendly', status: :enabled)
  end

  def calendly_client(hook)
    Calendly::ApiClient.new(hook.settings['access_token'])
  end

  def find_event_type_by_name(client, hook, name)
    response = client.event_types(user_uri: hook.settings['user_uri'])
    collection = response['collection'] || []

    match = collection.find do |et|
      et_name = et['name']&.downcase || ''
      query = name.downcase
      et_name.include?(query) || query.include?(et_name)
    end
    return match if match

    duration = name.scan(/\d+/).first&.to_i
    if duration
      match = collection.find { |et| et['duration'] == duration }
      return match if match
    end

    nil
  end

  def format_time_local(utc_string, timezone = 'Asia/Ho_Chi_Minh')
    time = Time.parse(utc_string)
    tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
    time.in_time_zone(tz).strftime('%H:%M %A, %d/%m/%Y')
  end

  def calendly_not_connected_message
    'Calendly is not connected. Please connect Calendly in Settings > Integrations.'
  end

  # --- Formatting helpers ---

  def format_event_types(types)
    lines = types.map do |et|
      duration = et['duration'] || 0
      name = et['name']
      desc = et['description_plain'].presence
      line = "- #{name} (#{duration} minutes)"
      line += "— #{desc}" if desc
      line
    end

    "Available services on Calendly:\n#{lines.join("\n")}\n\nIMPORTANT: When using other Calendly tools, you MUST pass the EXACT service name as listed above. Do not translate it."
  end

  def format_available_times(slots, event_type, timezone)
    grouped = slots.group_by do |slot|
      time = Time.parse(slot['start_time'])
      tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
      time.in_time_zone(tz).strftime('%A, %d/%m/%Y')
    end

    lines = ["Available time slots for #{event_type['name']} (#{event_type['duration']} minutes):"]
    grouped.each do |date, day_slots|
      time_list = day_slots.map do |slot|
        time = Time.parse(slot['start_time'])
        tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
        local_time = time.in_time_zone(tz).strftime('%H:%M')
        "#{local_time} (start_time: #{slot['start_time']})"
      end
      lines << "#{date}: #{time_list.join("\n - ")}"
    end

    lines << "\nIMPORTANT: When using the calendly_book_appointment tool, you MUST pass the exact `start_time` string provided in parentheses (e.g. 2024-05-25T03:30:00.000000Z). Do NOT construct the UTC time yourself."
    lines.join("\n")
  end

  def format_booking_confirmation(invitee, event_type, timezone)
    start = invitee['start_time'] ? format_time_local(invitee['start_time'], timezone) : 'N/A'
    reschedule_url = invitee['reschedule_url']
    cancel_url = invitee['cancel_url']

    lines = [
      'Booking successful!',
      "Service: #{event_type['name']}",
      "Time: #{start}",
      "Guest: #{invitee.dig('invitee', 'name') || invitee['name']}",
      "Email: #{invitee.dig('invitee', 'email') || invitee['email']}"
    ]
    lines << "Reschedule: #{reschedule_url}" if reschedule_url.present?
    lines << "Cancel: #{cancel_url}" if cancel_url.present?

    lines.join("\n")
  end

  def filter_events_by_email(client, events, email)
    events.select do |event|
      uuid = event['uri']&.split('/')&.last
      next false unless uuid

      invitees_response = client.event_invitees(event_uuid: uuid)
      invitees = invitees_response['collection'] || []
      invitees.any? { |inv| inv['email']&.downcase == email.downcase }
    end
  end

  def format_events(client, events, timezone)
    lines = ["Upcoming appointments (#{events.size}):"]
    events.first(10).each do |event|
      name = event['name'] || event.dig('event_type', 'name') || 'N/A'
      start_time = event['start_time'] ? format_time_local(event['start_time'], timezone) : 'N/A'
      status = event['status']

      uuid = event['uri']&.split('/')&.last
      invitee_info = 'N/A'
      if uuid
        begin
          invitees_response = client.event_invitees(event_uuid: uuid)
          invitees = invitees_response['collection'] || []
          if invitees.any?
            inv = invitees.first
            invitee_info = "#{inv['name']} (#{inv['email']})"
          end
        rescue Calendly::ApiClient::ApiError
          # Ignore if we can't fetch invitees
        end
      end

      lines << "- Service: #{name} | Guest: #{invitee_info} | Time: #{start_time} | Status: #{status}"
    end
    lines << "... and #{events.size - 10} other appointments" if events.size > 10
    lines.join("\n")
  end

  def find_upcoming_invitee(client, hook, email)
    response = client.scheduled_events(
      user_uri: hook.settings['user_uri'],
      min_start_time: Time.current,
      max_start_time: 30.days.from_now
    )
    events = response['collection'] || []

    events.each do |event|
      uuid = event['uri']&.split('/')&.last
      next unless uuid

      invitees_response = client.event_invitees(event_uuid: uuid)
      invitees = invitees_response['collection'] || []
      match = invitees.find { |inv| inv['email']&.downcase == email.downcase }

      return match.merge('event_name' => event['name'], 'event_start_time' => event['start_time']) if match
    end

    nil
  end

  def format_manage_response(invitee, action, timezone)
    event_name = invitee['event_name'] || 'N/A'
    start_time = invitee['event_start_time'] ? format_time_local(invitee['event_start_time'], timezone) : 'N/A'

    if action == 'reschedule'
      url = invitee['reschedule_url']
      return 'No reschedule link available for this appointment.' unless url

      "Reschedule appointment:\nService: #{event_name}\nCurrent schedule: #{start_time}\nReschedule link: #{url}"
    else
      url = invitee['cancel_url']
      return 'No cancel link available for this appointment.' unless url

      "Cancel appointment:\nService: #{event_name}\nCurrent schedule: #{start_time}\nCancel link: #{url}"
    end
  end
end
