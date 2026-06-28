class Conversations::TriggerAutoFollowUpJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, message_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    message = conversation.messages.find_by(id: message_id)
    return unless message

    # Abort if this message is no longer the last meaningful message
    last_meaningful = conversation.messages.where(message_type: [:incoming, :outgoing]).last
    return if last_meaningful && last_meaningful.id != message.id

    # Abort if auto follow up was cancelled manually
    return if conversation.custom_attributes['auto_follow_up_cancelled'] == true

    auto_follow_up_config = conversation.inbox.auto_follow_up_config || {}
    return unless auto_follow_up_config['enabled']

    max_attempts = [auto_follow_up_config['max_attempts'].to_i, 1].max

    is_automated = detect_automated_message(message)

    if is_automated
      current_count = conversation.custom_attributes['auto_follow_up_count'].to_i
      return if current_count >= max_attempts
    else
      conversation.with_lock do
        conversation.custom_attributes['auto_follow_up_count'] = 0
        conversation.custom_attributes['auto_follow_up_cancelled'] = false
        conversation.save!
      end
    end

    time_mode = auto_follow_up_config['time_mode'] || 'relative'
    interval_hours = auto_follow_up_config['interval_hours'].to_i
    delay_seconds = auto_follow_up_config['delay_seconds'].to_i

    return if interval_hours <= 0 && delay_seconds <= 0

    wait_until_time = calculate_wait_until(time_mode, interval_hours, delay_seconds, auto_follow_up_config, message.created_at)

    return if wait_until_time.nil? || wait_until_time <= message.created_at

    Conversations::AutoFollowUpExecutionJob.set(wait_until: wait_until_time).perform_later(conversation.id, message.id)

    formatted_time = wait_until_time.in_time_zone('Asia/Ho_Chi_Minh').strftime('%H:%M %d/%m/%Y')
    conversation.messages.create(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: I18n.t('conversations.activity.auto_follow_up.scheduled', time: formatted_time),
      content_attributes: {
        translation_key: 'CONVERSATION.ACTIVITY.auto_follow_up.scheduled',
        translation_values: { time: formatted_time }
      }
    )
  end

  private

  def detect_automated_message(message)
    return true if message.content_attributes['auto_follow_up_automated'] == true
    return true if message.sender.is_a?(AgentBot)
    return true if message.sender.nil?

    false
  end

  def calculate_wait_until(time_mode, interval_hours, delay_seconds, auto_follow_up_config, base_time)
    timezone_str = auto_follow_up_config['timezone'].presence || 'Asia/Ho_Chi_Minh'
    time_zone = ActiveSupport::TimeZone[timezone_str] || Time.zone

    if time_mode == 'fixed' && auto_follow_up_config['fixed_time'].present?
      target_hours, target_minutes = auto_follow_up_config['fixed_time'].split(':').map(&:to_i)
      min_wait_time = base_time + (interval_hours > 0 ? interval_hours.hours : delay_seconds.seconds)
      target_time = min_wait_time.in_time_zone(time_zone).change(hour: target_hours, min: target_minutes, sec: 0)

      target_time += 1.day if target_time < min_wait_time
      target_time.utc
    else
      base_time + (interval_hours > 0 ? interval_hours.hours : delay_seconds.seconds)
    end
  end
end
