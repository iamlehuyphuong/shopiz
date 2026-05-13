# Copilot tool: Gets reschedule/cancel links for an existing booking.
class Captain::Tools::Copilot::CalendlyManageBookingService < Captain::Tools::BaseTool
  def self.name
    'calendly_manage_booking'
  end

  description 'Get reschedule or cancel link for an existing Calendly booking by customer email.'

  param :customer_email, type: :string, desc: 'Email used when booking the appointment', required: true
  param :action, type: :string, desc: 'Action: "reschedule" or "cancel"', required: true

  def execute(customer_email:, action:)
    hook = find_calendly_hook
    return calendly_not_connected_message unless hook

    unless %w[reschedule cancel].include?(action)
      return "Hành động không hợp lệ. Chọn 'reschedule' (dời lịch) hoặc 'cancel' (hủy)."
    end

    client = calendly_client(hook)
    timezone = hook.settings['default_timezone'] || 'Asia/Ho_Chi_Minh'

    invitee = find_upcoming_invitee(client, hook, customer_email)
    return "Không tìm thấy cuộc hẹn sắp tới cho email #{customer_email}." unless invitee

    format_manage_response(invitee, action, timezone)
  rescue Calendly::ApiClient::ApiError => e
    "Calendly error: #{e.message}"
  end

  def active?
    @user.present? && find_calendly_hook.present?
  end

  private

  include Captain::Tools::Copilot::Concerns::CalendlyHelper
end
