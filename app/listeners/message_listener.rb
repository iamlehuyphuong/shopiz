class MessageListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return if message.nil?
    
    # Voice message delivery functionality has been removed for now
    # This would be where we'd handle delivering agent messages to voice calls
    
    # Extract contact info from message content
    ::Contacts::ContactInfoExtractorService.new(message).perform

    schedule_auto_follow_up(message)
    schedule_auto_label(message)
  end
  
  private
  
  def schedule_auto_follow_up(message)
    return unless message.outgoing?
    
    auto_follow_up_config = message.inbox.auto_follow_up_config || {}
    return unless auto_follow_up_config['enabled']

    conversation = message.conversation
    max_attempts = [auto_follow_up_config['max_attempts'].to_i, 1].max
    
    # 1. Sequence Limit Check
    is_automated = message.content_attributes['auto_follow_up_automated'] == true
    # Messages from AgentBot senders are also considered automated (e.g. macro/AI-generated)
    is_automated ||= message.sender.is_a?(AgentBot)
    if is_automated
      current_count = conversation.custom_attributes['auto_follow_up_count'].to_i
      # Bail if we reached the maximum loop of sequence
      return if current_count >= max_attempts
    else
      # Real agent message resets the count back to 0 and removes cancelled state
      conversation.with_lock do
        conversation.custom_attributes['auto_follow_up_count'] = 0
        conversation.custom_attributes['auto_follow_up_cancelled'] = false
        conversation.save!
      end
    end
    
    # 2. Compute Timing
    time_mode = auto_follow_up_config['time_mode'] || 'relative'
    interval_hours = auto_follow_up_config['interval_hours'].to_i
    delay_seconds = auto_follow_up_config['delay_seconds'].to_i
    
    return if interval_hours <= 0 && delay_seconds <= 0

    wait_until_time = calculate_wait_until(time_mode, interval_hours, delay_seconds, auto_follow_up_config)
    
    unless wait_until_time.nil? || wait_until_time <= Time.current
      Conversations::AutoFollowUpExecutionJob.set(wait_until: wait_until_time).perform_later(conversation.id, message.id)
      
      formatted_time = wait_until_time.in_time_zone('Asia/Ho_Chi_Minh').strftime('%H:%M %d/%m/%Y')
      conversation.messages.create(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: "Hệ thống đã kích hoạt lên lịch gửi tin nhắn bám đuổi (follow-up) tự động vào lúc #{formatted_time}.",
        content_attributes: {
          translation_key: 'CONVERSATION.ACTIVITY.auto_follow_up.scheduled',
          translation_values: { time: formatted_time }
        }
      )
    end
  end

  def calculate_wait_until(time_mode, interval_hours, delay_seconds, auto_follow_up_config)
    timezone_str = auto_follow_up_config['timezone'].presence || 'Asia/Ho_Chi_Minh'
    time_zone = ActiveSupport::TimeZone[timezone_str] || Time.zone

    if time_mode == 'fixed' && auto_follow_up_config['fixed_time'].present?
      target_hours, target_minutes = auto_follow_up_config['fixed_time'].split(':').map(&:to_i)
      
      min_wait_time = Time.current + (interval_hours > 0 ? interval_hours.hours : delay_seconds.seconds)
      
      # Evaluate the target day in the target timezone
      target_time = min_wait_time.in_time_zone(time_zone).change(hour: target_hours, min: target_minutes, sec: 0)
      
      # Push exactly to the next day slot if changing the clock rolled time backwards behind minimum wait required
      target_time += 1.day if target_time < min_wait_time
      
      target_time.utc
    else
      Time.current + (interval_hours > 0 ? interval_hours.hours : delay_seconds.seconds)
    end
  end
  
  def extract_message_and_account(event)
    message = event.data[:message]
    account = message.account
    [message, account]
  end

  def schedule_auto_label(message)
    return unless message.incoming?
    return unless message.account.feature_enabled?('captain_tasks')

    # Trigger 1: Every 5 incoming messages
    incoming_count = message.conversation.messages.incoming.count
    if incoming_count > 0 && incoming_count % 5 == 0
      Captain::AutoLabelJob.perform_async(message.conversation_id, 'count')
    end

    # Trigger 2: 15 minutes after the last incoming message (if customer stops responding)
    Captain::AutoLabelJob.set(wait: 15.minutes).perform_later(message.conversation_id, 'delay')
  end
end