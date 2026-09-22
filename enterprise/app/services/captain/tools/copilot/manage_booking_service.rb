# Copilot tool: General Manage Booking router
class Captain::Tools::Copilot::ManageBookingService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'manage_booking'
  end

  description 'Get reschedule or cancel link for an existing booking by customer email. Routes to Calendly, Cal.com, or Google Calendar.'

  param :customer_email, type: :string, desc: 'Email used when booking the appointment', required: true
  param :action, type: :string, desc: 'Action: "reschedule" or "cancel"', required: true

  def execute(**args)
    delegate_to_booking_tool(**args)
  end

  private

  def booking_platform_tools
    { 'calendly' => 'Captain::Tools::Copilot::Calendly::ManageBookingService' }.freeze
  end
end
