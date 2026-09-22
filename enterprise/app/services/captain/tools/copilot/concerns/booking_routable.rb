module Captain::Tools::Copilot::Concerns::BookingRoutable
  extend ActiveSupport::Concern

  def active?
    @user.present? && resolve_booking_platform.present?
  end

  private

  # Map platform => Specific Tool Class Name
  def booking_platform_tools
    raise NotImplementedError, 'Subclasses must implement booking_platform_tools'
  end

  def resolve_booking_platform
    return nil unless @assistant

    account = @assistant.account
    return 'calendly' if account.hooks.exists?(app_id: 'calendly', status: :enabled)

    # Future: 'google_calendar', 'cal_com', etc.
    nil
  end

  def delegate_to_booking_tool(**args)
    platform = resolve_booking_platform
    return 'No booking integration found.' unless platform

    tool_class_name = booking_platform_tools[platform]
    return "Booking not supported for #{platform}." unless tool_class_name

    tool_class = tool_class_name.safe_constantize
    return "Tool class #{tool_class_name} not found." unless tool_class

    tool = tool_class.new(@assistant, user: @user)
    return 'Booking integration not configured.' unless tool.active?

    tool.execute(**args)
  end
end
