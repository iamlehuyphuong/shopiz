class Captain::Tools::GetBookingLinkTool < Captain::Tools::BasePublicTool
  description 'Retrieve the public booking link to send to the user'

  def active?
    return false unless @assistant&.account

    @assistant.account.hooks.exists?(app_id: 'calendly') ||
      @assistant.account.booking_configurations.exists?(is_active: true)
  end

  def perform(tool_context, **_args)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    account = conversation.account

    # If Calendly is configured, prefer it or fetch it based on logic.
    # Assuming we check Google Calendar first or Calendly first.
    # Here we just fetch the local booking link if active.
    config = account.booking_configurations.find_by(is_active: true)
    if config && config.booking_link_hash.present?
      # Assuming the public route is /b/:hash
      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      booking_url = "#{frontend_url}/b/#{config.booking_link_hash}"
      return "You can book a meeting using this link: #{booking_url}"
    end

    'No booking link configured for this account.'
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to get booking link'
  end
end
