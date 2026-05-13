class Webhooks::CalendlyController < ActionController::API
  def events
    Rails.logger.info("Calendly webhook received: #{event_type}")

    case event_type
    when 'invitee.created'
      handle_invitee_created
    when 'invitee.canceled'
      handle_invitee_canceled
    end

    head :ok
  end

  private

  def event_type
    params.dig(:event)
  end

  def payload
    params.dig(:payload)
  end

  def handle_invitee_created
    return unless payload

    invitee_email = payload.dig(:email)
    invitee_name = payload.dig(:name)
    event_name = payload.dig(:event_type, :name)
    start_time = payload.dig(:scheduled_event, :start_time)
    end_time = payload.dig(:scheduled_event, :end_time)
    reschedule_url = payload.dig(:reschedule_url)
    cancel_url = payload.dig(:cancel_url)

    note = build_created_note(
      invitee_name: invitee_name,
      invitee_email: invitee_email,
      event_name: event_name,
      start_time: start_time,
      end_time: end_time,
      reschedule_url: reschedule_url,
      cancel_url: cancel_url
    )

    create_private_notes_for_contact(invitee_email, note)
  end

  def handle_invitee_canceled
    return unless payload

    invitee_email = payload.dig(:email)
    invitee_name = payload.dig(:name)
    event_name = payload.dig(:event_type, :name)
    start_time = payload.dig(:scheduled_event, :start_time)
    reason = payload.dig(:cancellation, :reason)

    note = build_canceled_note(
      invitee_name: invitee_name,
      invitee_email: invitee_email,
      event_name: event_name,
      start_time: start_time,
      reason: reason
    )

    create_private_notes_for_contact(invitee_email, note)
  end

  # Find open conversations for the contact matching the invitee email,
  # and create a private note in each one.
  def create_private_notes_for_contact(email, note)
    return if email.blank? || note.blank?

    # Find all contacts matching this email across accounts with Calendly hooks
    calendly_hooks = Integrations::Hook.where(app_id: 'calendly', status: :enabled)

    calendly_hooks.find_each do |hook|
      account = hook.account
      contacts = account.contacts.where(email: email)

      contacts.find_each do |contact|
        # Find the most recent open conversation for this contact
        conversation = contact.conversations
                              .where(status: [:open, :pending])
                              .order(last_activity_at: :desc)
                              .first

        next unless conversation

        conversation.messages.create!(
          account: account,
          inbox: conversation.inbox,
          message_type: :activity,
          content: note
        )

        Rails.logger.info(
          "Calendly: Private note added to conversation ##{conversation.display_id} for #{email}"
        )
      end
    end
  end

  def build_created_note(invitee_name:, invitee_email:, event_name:, start_time:, end_time:, reschedule_url:, cancel_url:)
    formatted_time = format_time(start_time)
    lines = [
      "📅 **Calendly: Lịch hẹn mới**",
      "• Dịch vụ: #{event_name}",
      "• Khách: #{invitee_name} (#{invitee_email})",
      "• Thời gian: #{formatted_time}"
    ]
    lines << "• Dời lịch: #{reschedule_url}" if reschedule_url.present?
    lines << "• Hủy lịch: #{cancel_url}" if cancel_url.present?
    lines.join("\n")
  end

  def build_canceled_note(invitee_name:, invitee_email:, event_name:, start_time:, reason:)
    formatted_time = format_time(start_time)
    lines = [
      "❌ **Calendly: Lịch hẹn đã hủy**",
      "• Dịch vụ: #{event_name}",
      "• Khách: #{invitee_name} (#{invitee_email})",
      "• Thời gian: #{formatted_time}"
    ]
    lines << "• Lý do: #{reason}" if reason.present?
    lines.join("\n")
  end

  def format_time(utc_string)
    return 'N/A' if utc_string.blank?

    time = Time.parse(utc_string)
    tz = ActiveSupport::TimeZone['Asia/Ho_Chi_Minh']
    time.in_time_zone(tz).strftime('%H:%M %A, %d/%m/%Y')
  rescue StandardError
    utc_string
  end
end
