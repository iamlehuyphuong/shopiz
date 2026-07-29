# Copilot tool: General Manage Booking router
class Captain::Tools::Copilot::ManageBookingService < Captain::Tools::BaseTool
  def self.name
    'manage_booking'
  end

  description 'Get reschedule or cancel link for an existing booking by customer email. Routes to Calendly, Cal.com, or Google Calendar.'

  param :customer_email, type: :string, desc: 'Email used when booking the appointment', required: true
  param :action, type: :string, desc: 'Action: "reschedule" or "cancel"', required: true

  def execute(**args)
    # Temporary router logic: default to Calendly for now.
    Captain::Tools::Copilot::CalendlyManageBookingService.new(@assistant, user: @user).execute(**args)
  end

  def active?
    # True if ANY booking provider is connected.
    Captain::Tools::Copilot::CalendlyManageBookingService.new(@assistant, user: @user).active?
  end
end
