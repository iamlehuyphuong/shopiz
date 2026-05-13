# Shared concern for Calendly tools.
# Provides helper methods to find the Calendly integration hook,
# build the API client, and fuzzy-match event types by name.
module Captain::Tools::Concerns::CalendlyClient
  extend ActiveSupport::Concern

  private

  # Find the active Calendly integration hook for the account.
  def find_calendly_hook(tool_context)
    conversation = find_conversation(tool_context.state)
    return nil unless conversation

    conversation.account.hooks.find_by(app_id: 'calendly', status: :enabled)
  end

  def calendly_client(hook)
    token = hook.settings['access_token']
    Calendly::ApiClient.new(token)
  end

  # Fuzzy match event type by name keyword.
  # Returns the first event type whose name includes the search term (case-insensitive).
  def find_event_type_by_name(client, hook, name)
    response = client.event_types(user_uri: hook.settings['user_uri'])
    collection = response['collection'] || []

    collection.find { |et| et['name']&.downcase&.include?(name.downcase) }
  end

  # Format a UTC ISO-8601 time into a human-readable local time.
  def format_time_local(utc_string, timezone = 'Asia/Ho_Chi_Minh')
    time = Time.parse(utc_string)
    tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
    time.in_time_zone(tz).strftime('%H:%M %A, %d/%m/%Y')
  end

  def calendly_not_connected_message
    'Calendly chưa được kết nối. Vui lòng kết nối Calendly trong Cài đặt > Tích hợp.'
  end
end
