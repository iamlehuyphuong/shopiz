# Copilot tool: General Get Available Times router
class Captain::Tools::Copilot::GetAvailableTimesService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'get_available_times'
  end

  description 'Get available time slots for an appointment. Routes to Calendly, Cal.com, or Google Calendar. Max 7 days per query.'

  param :event_type_name, type: :string, desc: 'Name or keyword of the event type (e.g. "Tư vấn", "Demo")', required: true
  param :preferred_date, type: :string, desc: 'Preferred date in YYYY-MM-DD format', required: false
  param :days_ahead, type: :integer, desc: 'Number of days to look ahead from preferred_date (max 7)', required: false

  def execute(**args)
    delegate_to_booking_tool(**args)
  end

  private

  def booking_platform_tools
    { 'calendly' => 'Captain::Tools::Copilot::Calendly::GetAvailableTimesService' }.freeze
  end
end
