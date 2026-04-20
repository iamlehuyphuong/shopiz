class MessageListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return if message.nil?
    
    # Voice message delivery functionality has been removed for now
    # This would be where we'd handle delivering agent messages to voice calls
    
    # Extract contact info from message content
    ::Contacts::ContactInfoExtractorService.new(message).perform

    schedule_followup(message)
  end
  
  private
  
  def schedule_followup(message)
    return unless message.outgoing?
    
    followup_config = message.inbox.followup_config || {}
    return unless followup_config['enabled']

    conversation = message.conversation
    max_attempts = [followup_config['max_attempts'].to_i, 1].max
    
    # 1. Sequence Limit Check
    is_automated = message.content_attributes['followup_automated'] == true
    if is_automated
      current_count = conversation.custom_attributes['followup_count'].to_i
      # Bail if we reached the maximum loop of sequence
      return if current_count >= max_attempts
    else
      # Real agent message resets the count back to 0
      conversation.custom_attributes['followup_count'] = 0
      conversation.save!
    end
    
    # 2. Compute Timing
    time_mode = followup_config['time_mode'] || 'relative'
    interval_hours = followup_config['interval_hours'].to_i
    delay_seconds = followup_config['delay_seconds'].to_i
    
    return if interval_hours <= 0 && delay_seconds <= 0

    wait_until_time = calculate_wait_until(time_mode, interval_hours, delay_seconds, followup_config)
    
    unless wait_until_time.nil? || wait_until_time <= Time.current
      Conversations::FollowupExecutionJob.set(wait_until: wait_until_time).perform_later(conversation.id, message.id)
    end
  end

  def calculate_wait_until(time_mode, interval_hours, delay_seconds, followup_config)
    timezone_str = followup_config['timezone'].presence || 'Asia/Ho_Chi_Minh'
    time_zone = ActiveSupport::TimeZone[timezone_str] || Time.zone

    if time_mode == 'fixed' && followup_config['fixed_time'].present?
      target_hours, target_minutes = followup_config['fixed_time'].split(':').map(&:to_i)
      
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
end