class Captain::Tools::Copilot::GetBookingLinkService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'get_booking_link'
  end

  description 'Retrieve the public booking link to send to the user'

  def execute(**_args)
    # If Calendly is configured, prefer it or fetch it based on logic.
    # Assuming we check Google Calendar first or Calendly first.
    # Here we just fetch the local booking link if active.
    config = @assistant.account.booking_configurations.find_by(is_active: true)
    if config && config.booking_link_hash.present?
      # Assuming the public route is /b/:hash
      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      booking_url = "#{frontend_url}/b/#{config.booking_link_hash}"
      return "You can book a meeting using this link: #{booking_url}"
    end

    # For Calendly, we can get user_uri from hook settings and generate a calendly link
    # But usually calendly links are user specific, we can try to fetch it from hook
    calendly_hook = @assistant.account.hooks.find_by(app_id: 'calendly', status: :enabled)
    if calendly_hook
      scheduling_url = calendly_hook.settings['scheduling_url']
      return "You can book a meeting using this link: #{scheduling_url}" if scheduling_url.present?
    end

    'No booking link configured for this account.'
  rescue StandardError => e
    "Failed to get booking link: #{e.message}"
  end

  private

  # We don't use delegate_to_booking_tool here because we don't have a platform-specific tool class for this
  def booking_platform_tools
    {}
  end
end
