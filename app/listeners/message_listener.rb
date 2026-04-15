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
    
    delay_seconds = followup_config['delay_seconds'].to_i
    return unless delay_seconds > 0
    
    Conversations::FollowupExecutionJob.set(wait: delay_seconds.seconds).perform_later(message.conversation.id, message.id)
  end
  
  def extract_message_and_account(event)
    message = event.data[:message]
    account = message.account
    [message, account]
  end
end