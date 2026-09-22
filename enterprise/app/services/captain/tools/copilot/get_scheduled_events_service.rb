class Captain::Tools::Copilot::GetScheduledEventsService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'get_scheduled_events'
  end

  description 'Get upcoming scheduled appointments. Optionally filter by customer email.'

  param :customer_email, type: :string, desc: 'Filter events by customer email', required: false
  param :days_ahead, type: :integer, desc: 'Number of days to look ahead (default 14)', required: false

  def execute(**args)
    delegate_to_booking_tool(**args)
  end

  private

  def booking_platform_tools
    { 'calendly' => 'Captain::Tools::Copilot::Calendly::GetScheduledEventsService' }.freeze
  end
end
