class Captain::Tools::Copilot::ListEventTypesService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::BookingRoutable

  def self.name
    'list_event_types'
  end

  description 'List available appointment types/services for booking (e.g. Consultation, Demo)'

  def execute(**args)
    delegate_to_booking_tool(**args)
  end

  private

  def booking_platform_tools
    { 'calendly' => 'Captain::Tools::Copilot::Calendly::ListEventTypesService' }.freeze
  end
end
