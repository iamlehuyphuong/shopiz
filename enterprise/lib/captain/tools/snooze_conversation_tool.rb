class Captain::Tools::SnoozeConversationTool < Captain::Tools::BasePublicTool
  description 'Snooze a conversation to follow up later. The conversation will reappear after the specified duration.'
  param :duration, type: 'string',
                   desc: 'How long to snooze: "1_hour", "2_hours", "4_hours", "6_hours", "1_day", "2_days", or "1_week"'

  SNOOZE_DURATIONS = {
    '1_hour' => 1.hour,
    '2_hours' => 2.hours,
    '4_hours' => 4.hours,
    '6_hours' => 6.hours,
    '1_day' => 1.day,
    '2_days' => 2.days,
    '1_week' => 1.week
  }.freeze

  def perform(tool_context, duration:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation
    return 'Conversation is already resolved' if conversation.resolved?

    snooze_duration = SNOOZE_DURATIONS[duration]
    return "Invalid duration. Valid options: #{SNOOZE_DURATIONS.keys.join(', ')}" unless snooze_duration

    snoozed_until = Time.current + snooze_duration
    conversation.update!(status: :snoozed, snoozed_until: snoozed_until)

    log_tool_usage('snooze_conversation', { conversation_id: conversation.id, duration: duration, snoozed_until: snoozed_until })

    "Conversation ##{conversation.display_id} snoozed until #{snoozed_until.strftime('%Y-%m-%d %H:%M %Z')}"
  end

  private

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
