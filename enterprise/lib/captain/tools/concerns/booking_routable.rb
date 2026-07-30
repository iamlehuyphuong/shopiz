# Shared concern for routing tool calls to the correct booking platform.
# Include in any "base" booking tool that should auto-delegate to a platform-specific
# tool when the conversation's inbox is linked to a booking integration (Calendly or Google Calendar).
#
# Usage:
#   include Captain::Tools::Concerns::BookingRoutable
#
#   # Define the mapping in the subclass:
#   def calendly_tool_class
#     'Captain::Tools::CalendlyGetAvailableTimesTool'
#   end
#
#   # In perform:
#   platform = resolve_booking_platform(tool_context)
#   if platform == 'calendly'
#     result = delegate_to_calendly_tool(tool_context, **args)
#     return result if result
#   end
#   # ... fallback to Google Calendar ...
module Captain::Tools::Concerns::BookingRoutable
  extend ActiveSupport::Concern

  private

  # Resolves the booking platform app_id from the account settings.
  # Returns 'calendly', 'google_calendar', or nil.
  def resolve_booking_platform(tool_context)
    conversation = find_conversation(tool_context.state)
    return nil unless conversation

    account = conversation.account
    return nil unless account

    # Check Calendly
    return 'calendly' if account.hooks.exists?(app_id: 'calendly')

    # Check Google Calendar
    return 'google_calendar' if account.booking_configurations.exists?(is_active: true)

    nil
  end

  # Instantiates the Calendly specific tool and delegates the perform call.
  # Subclasses MUST override `calendly_tool_class` to return the appropriate class name.
  def delegate_to_calendly_tool(tool_context, **args)
    tool_class_name = calendly_tool_class
    return nil unless tool_class_name

    tool_class = tool_class_name.safe_constantize
    return nil unless tool_class

    log_tool_usage('booking_route:calendly', args)
    tool_class.new(@assistant).perform(tool_context, **args)
  end

  # Subclasses must provide the Calendly equivalent tool class name
  def calendly_tool_class
    nil
  end
end
