# Copilot tool: Gets upcoming Calendly events for the agent.
class Captain::Tools::Copilot::CalendlyGetScheduledEventsService < Captain::Tools::BaseTool
  def self.name
    'calendly_get_scheduled_events'
  end

  description 'Get upcoming scheduled Calendly appointments. Optionally filter by customer email.'

  param :customer_email, type: :string, desc: 'Filter events by customer email', required: false
  param :days_ahead, type: :integer, desc: 'Number of days to look ahead (default 14)', required: false

  def execute(customer_email: nil, days_ahead: 14)
    hook = find_calendly_hook
    return calendly_not_connected_message unless hook

    client = calendly_client(hook)
    timezone = hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'

    response = client.scheduled_events(
      user_uri: hook.settings['user_uri'],
      min_start_time: Time.current,
      max_start_time: Time.current + days_ahead.to_i.days
    )
    events = response['collection'] || []

    return 'No upcoming appointments found.' if events.empty?

    if customer_email.present?
      events = filter_events_by_email(client, events, customer_email)
      return "No appointments found for email #{customer_email}." if events.empty?
    end

    format_events(client, events, timezone)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly API Error: #{e.message} - #{e.body.to_json}"
  rescue StandardError => e
    "System error calling Calendly: #{e.message}"
  end

  def active?
    @user.present? && find_calendly_hook.present?
  end

  include Captain::Tools::Copilot::Concerns::CalendlyHelper
end
