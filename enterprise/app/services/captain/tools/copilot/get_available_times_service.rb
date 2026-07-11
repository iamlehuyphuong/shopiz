# Copilot tool: General Get Available Times router
class Captain::Tools::Copilot::GetAvailableTimesService < Captain::Tools::BaseTool
  def self.name
    'get_available_times'
  end

  description 'Get available time slots for an appointment. Routes to Calendly, Cal.com, or Google Calendar. Max 7 days per query.'

  param :event_type_name, type: :string, desc: 'Name or keyword of the event type (e.g. "Tư vấn", "Demo")', required: true
  param :preferred_date, type: :string, desc: 'Preferred date in YYYY-MM-DD format', required: false
  param :days_ahead, type: :integer, desc: 'Number of days to look ahead from preferred_date (max 7)', required: false

  def execute(**args)
    # Temporary router logic: default to Calendly for now.
    Captain::Tools::Copilot::CalendlyGetAvailableTimesService.new(@assistant, user: @user).execute(**args)
  end

  def active?
    # True if ANY booking provider is connected.
    Captain::Tools::Copilot::CalendlyGetAvailableTimesService.new(@assistant, user: @user).active?
  end
end
