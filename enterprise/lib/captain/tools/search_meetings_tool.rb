class Captain::Tools::SearchMeetingsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::BookingRoutable

  description 'Search for upcoming booked meetings/appointments for a guest'

  param :guest_email, type: 'string', desc: 'The email address of the guest to search for', required: false
  param :days_ahead, type: 'integer', desc: 'Number of days to look ahead (default 14)', required: false

  def perform(tool_context, guest_email: nil, days_ahead: 14)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    email_to_search = guest_email || conversation.contact&.email
    days_ahead = (days_ahead || 14).to_i

    # Route to booking platform if configured
    platform = resolve_booking_platform(tool_context)
    if platform == 'calendly'
      return delegate_to_calendly_tool(
        tool_context,
        customer_email: email_to_search,
        days_ahead: days_ahead
      )
    end

    # Fallback to local DB (Google Calendar bookings)
    bookings = find_local_bookings(conversation, email_to_search, days_ahead)
    return "No upcoming meetings found#{email_to_search ? " for #{email_to_search}" : ''}." if bookings.empty?

    log_tool_usage('search_meetings', { conversation_id: conversation.id, email: email_to_search })
    format_local_bookings(bookings)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to search for meetings'
  end

  private

  def calendly_tool_class
    'Captain::Tools::Calendly::GetScheduledEventsTool'
  end

  def find_local_bookings(conversation, email, days_ahead)
    query = conversation.account.bookings.where('start_time >= ?', Time.current)
    query = query.where('start_time <= ?', Time.current + days_ahead.days) if days_ahead.positive?
    query = query.where(status: :scheduled)

    if email.present?
      query = query.where('guest_email ILIKE ?', email)
    elsif conversation.contact_id
      # If no email provided, at least limit to the current contact's bookings
      query = query.where(contact_id: conversation.contact_id)
    end

    query.order(start_time: :asc).limit(10)
  end

  def format_local_bookings(bookings)
    lines = ["Found #{bookings.size} upcoming meeting(s):"]

    bookings.each do |booking|
      start_time = booking.start_time&.in_time_zone&.strftime('%Y-%m-%d %H:%M') || 'N/A'
      provider = booking.provider || 'local'
      lines << "- #{start_time} | Guest: #{booking.guest_name} (#{booking.guest_email}) | Provider: #{provider}"
    end

    lines.join("\n")
  end
end
