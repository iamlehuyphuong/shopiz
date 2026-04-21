class Conversations::FollowupExecutionJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, trigger_message_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    # Abort if the conversation is no longer open
    return unless conversation.status == 'open' || conversation.status == 'snoozed'

    trigger_message = Message.find_by(id: trigger_message_id)
    return unless trigger_message

    inbox = conversation.inbox

    # WebWidget channels do not support follow ups
    return if inbox.channel_type == 'Channel::WebWidget'

    followup_config = inbox.followup_config || {}
    return unless followup_config['enabled']

    # Guard: check if channel policy allows freeform messaging at this time
    unless channel_policy_allows_followup?(conversation)
      Rails.logger.info("[FollowupExecutionJob] Follow-up aborted due to strict channel policy limits on timestamp for #{conversation.id}.")
      return
    end

    # Guard: check if the customer has replied since the trigger message
    if customer_replied_after?(conversation, trigger_message.created_at)
      Rails.logger.info("[FollowupExecutionJob] Customer has replied to #{conversation.id} after the scheduled followup. Aborting.")
      return
    end

    # Guard: check if a newer outgoing message was sent by an agent after the trigger
    if agent_messaged_after?(conversation, trigger_message.created_at)
      Rails.logger.info("[FollowupExecutionJob] Agent sent a newer message. The followup will be handled by the newer message's job. Aborting.")
      return
    end

    action_type = followup_config['action_type']
    attempt_count = conversation.custom_attributes['followup_count'].to_i

    if action_type == 'ai_assistant'
      trigger_ai_assistant(conversation, attempt_count)
    elsif action_type == 'macro'
      macros_list = followup_config['macros'] || []
      macro_id = macros_list[attempt_count].presence || followup_config['macro_id']
      trigger_macro(conversation, macro_id, attempt_count) if macro_id.present?
    elsif action_type == 'predefined_message'
      messages_list = followup_config['predefined_messages'] || []
      content = messages_list[attempt_count].presence || followup_config['predefined_message']
      trigger_predefined_message(conversation, content, attempt_count) if content.present?
    end
  end

  private

  def channel_policy_allows_followup?(conversation)
    inbox = conversation.inbox
    
    # Calculate time since the customer's last interaction
    last_incoming = conversation.messages.where(message_type: 'incoming').last
    last_interaction_at = last_incoming&.created_at || conversation.created_at
    time_since_interaction = Time.current - last_interaction_at

    case inbox.channel_type
    when 'Channel::FacebookPage' # Covers FB and Instagram if routed here
      time_since_interaction <= 7.days
    when 'Channel::Whatsapp'
      time_since_interaction <= 24.hours
    when 'Channel::Zalo', 'Channel::ZaloPersonal'
      time_since_interaction <= 48.hours
    else
      true # Other channels have no strict API timeout limits for freeform text
    end
  end

  def customer_replied_after?(conversation, timestamp)
    conversation.messages.where(message_type: 'incoming').where('created_at > ?', timestamp).exists?
  end

  def agent_messaged_after?(conversation, timestamp)
    conversation.messages.where(message_type: 'outgoing').where('created_at > ?', timestamp).exists?
  end

  def trigger_ai_assistant(conversation, attempt_count)
    inbox = conversation.inbox
    assistant = inbox.agent_bot || conversation.account.agent_bots.first
    
    unless assistant
      Rails.logger.warn("[FollowupExecutionJob] No AI Assistant found for Inbox #{inbox.id}. Aborting follow-up.")
      return
    end

    # Increment count immediately so the next followup knows it's attempt_count + 1
    conversation.custom_attributes['followup_count'] = attempt_count + 1
    conversation.save!

    Captain::Conversation::FollowupBuilderJob.perform_later(conversation, assistant, attempt_count)
  end

  def trigger_macro(conversation, macro_id, attempt_count)
    macro = conversation.account.macros.find_by(id: macro_id)
    return unless macro

    conversation.custom_attributes['followup_count'] = attempt_count + 1
    conversation.save!

    Macros::ExecutionService.new(macro, nil, conversation).perform
  end

  def trigger_predefined_message(conversation, content, attempt_count)
    conversation.custom_attributes['followup_count'] = attempt_count + 1
    conversation.save!

    # Create the automated message using MessageBuilder to fire appropriate integrations
    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: 'outgoing',
      content: content,
      private: false,
      content_attributes: { followup_automated: true }
    }

    builder = MessageBuilder.new(message_params, conversation)
    builder.perform
  end
end
