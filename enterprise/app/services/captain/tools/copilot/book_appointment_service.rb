# Copilot tool: General Book Appointment router
class Captain::Tools::Copilot::BookAppointmentService < Captain::Tools::BaseTool
  def self.name
    'book_appointment'
  end

  description 'Book an appointment for the customer. Routes to Calendly, Cal.com, or Google Calendar.'

  param :event_type_name, type: :string, desc: 'Name or keyword of the event type to book', required: true
  param :start_time, type: :string, desc: 'Selected time slot in UTC ISO-8601 format (e.g. 2025-01-15T07:00:00Z)', required: true
  param :customer_name, type: :string, desc: 'Customer full name', required: true
  param :customer_email, type: :string, desc: 'Customer email address', required: true
  param :timezone, type: :string, desc: 'IANA timezone (e.g. Asia/Ho_Chi_Minh)', required: false

  def execute(**args)
    # Temporary router logic: default to Calendly for now.
    Captain::Tools::Copilot::CalendlyBookAppointmentService.new(@assistant, user: @user).execute(**args)
  end

  def active?
    # True if ANY booking provider is connected.
    Captain::Tools::Copilot::CalendlyBookAppointmentService.new(@assistant, user: @user).active?
  end
end
