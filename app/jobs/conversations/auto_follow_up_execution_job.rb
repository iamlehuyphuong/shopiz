class Conversations::AutoFollowUpExecutionJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, trigger_message_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    # Abort if the conversation is no longer open, unless it is pending and assigned to a bot
    is_bot_pending = conversation.status == 'pending' && conversation.assigned_entity.is_a?(AgentBot)
    return unless conversation.status == 'open' || conversation.status == 'snoozed' || is_bot_pending

    trigger_message = Message.find_by(id: trigger_message_id)
    return unless trigger_message

    inbox = conversation.inbox

    # WebWidget channels do not support follow ups
    return if inbox.channel_type == 'Channel::WebWidget'

    auto_follow_up_config = inbox.auto_follow_up_config || {}
    return unless auto_follow_up_config['enabled']

    # Guard: check if follow-up is manually cancelled
    if conversation.custom_attributes['auto_follow_up_cancelled'] == true
      Rails.logger.info("[AutoFollowUpExecutionJob] Follow-up manually cancelled for #{conversation.id}. Aborting.")
      return
    end

    # Guard: check if channel policy allows freeform messaging at this time
    unless channel_policy_allows_followup?(conversation)
      Rails.logger.info("[AutoFollowUpExecutionJob] Follow-up aborted due to strict channel policy limits on timestamp for #{conversation.id}.")
      log_activity(
        conversation,
        I18n.t('conversations.activity.auto_follow_up.cancelled_channel_policy'),
        'CONVERSATION.ACTIVITY.auto_follow_up.cancelled_channel_policy'
      )
      return
    end

    # Guard: check if the customer has replied since the trigger message
    if customer_replied_after?(conversation, trigger_message.created_at)
      Rails.logger.info("[AutoFollowUpExecutionJob] Customer has replied to #{conversation.id} after the scheduled followup. Aborting.")
      log_activity(
        conversation,
        I18n.t('conversations.activity.auto_follow_up.cancelled_customer_replied'),
        'CONVERSATION.ACTIVITY.auto_follow_up.cancelled_customer_replied'
      )
      return
    end

    # Guard: check if a newer outgoing message was sent by an agent after the trigger
    if agent_messaged_after?(conversation, trigger_message.created_at)
      Rails.logger.info("[AutoFollowUpExecutionJob] Agent sent a newer message. The followup will be handled by the newer message's job. Aborting.")
      # Không log "huỷ" ở đây vì sẽ bị spam (job mới đã được tạo và log kích hoạt mới rồi).
      return
    end

    attempt_count = conversation.custom_attributes['auto_follow_up_count'].to_i

    messages_list = auto_follow_up_config['predefined_messages'] || []
    base_message = messages_list[attempt_count].presence || auto_follow_up_config['predefined_message']

    if base_message.present?
      ai_rewrite_enabled = auto_follow_up_config['ai_rewrite'] == true
      assistant = inbox.agent_bot || conversation.account.agent_bots.first

      if ai_rewrite_enabled && assistant.present?
        trigger_ai_assistant(conversation, attempt_count, base_message)
      else
        trigger_predefined_message(conversation, base_message, attempt_count)
      end
    end

    log_activity(
      conversation,
      I18n.t('conversations.activity.auto_follow_up.completed', attempt: attempt_count + 1),
      'CONVERSATION.ACTIVITY.auto_follow_up.completed',
      { attempt: attempt_count + 1 }
    )
  end

  private

  def channel_policy_allows_followup?(conversation)
    Conversations::MessageWindowService.new(conversation).can_reply?
  end

  def customer_replied_after?(conversation, timestamp)
    conversation.messages.where(message_type: 'incoming').where('created_at > ?', timestamp).exists?
  end

  def agent_messaged_after?(conversation, timestamp)
    conversation.messages.where(message_type: 'outgoing').where('created_at > ?', timestamp).exists?
  end

  def trigger_ai_assistant(conversation, attempt_count, base_message)
    inbox = conversation.inbox
    assistant = inbox.agent_bot || conversation.account.agent_bots.first

    unless assistant
      Rails.logger.warn("[AutoFollowUpExecutionJob] No AI Assistant found for Inbox #{inbox.id}. Aborting follow-up.")
      log_activity(
        conversation,
        I18n.t('conversations.activity.auto_follow_up.cancelled_no_ai'),
        'CONVERSATION.ACTIVITY.auto_follow_up.cancelled_no_ai'
      )
      return
    end

    # Re-read count inside lock to avoid stale reads from concurrent jobs
    conversation.with_lock do
      attempt_count = conversation.custom_attributes['auto_follow_up_count'].to_i
      conversation.custom_attributes['auto_follow_up_count'] = attempt_count + 1
      conversation.save!
    end

    Captain::Conversation::FollowupBuilderJob.perform_later(conversation, assistant, attempt_count, base_message)
  end

  def trigger_predefined_message(conversation, content, attempt_count)
    # Re-read count inside lock to avoid stale reads from concurrent jobs
    conversation.with_lock do
      attempt_count = conversation.custom_attributes['auto_follow_up_count'].to_i
      conversation.custom_attributes['auto_follow_up_count'] = attempt_count + 1
      conversation.save!
    end

    # Create the automated message using MessageBuilder to fire appropriate integrations
    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: 'outgoing',
      content: content,
      private: false,
      content_attributes: { auto_follow_up_automated: true }
    }

    builder = Messages::MessageBuilder.new(nil, conversation, message_params)
    builder.perform
  end

  def log_activity(conversation, content, translation_key, translation_values = {})
    conversation.messages.create(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content,
      content_attributes: {
        translation_key: translation_key,
        translation_values: translation_values
      }
    )
  end
end
