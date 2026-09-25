# frozen_string_literal: true

class Captain::Conversation::CommentReplyBuilderJob < ApplicationJob
  queue_as :default

  SUPPORTED_CHANNELS = [Channel::FacebookPage, Channel::Instagram, Channel::Tiktok].freeze

  def perform(conversation_id, comment_id:, post_id:, message:, platform:, reply_type: 'private', comment_created_at: nil)
    @conversation = Conversation.find_by(id: conversation_id)
    return unless @conversation

    @channel = @conversation.inbox.channel
    return unless supported_channel?
    return if comment_too_old?(comment_id, comment_created_at)

    generated_text = generate_reply_text(message, post_id, platform, reply_type)

    if generated_text.blank?
      msg = @conversation.messages.create!(
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        message_type: :outgoing,
        content: 'AI Assistant failed to generate a reply.',
        status: :failed,
        source_id: "failed_ai_#{SecureRandom.hex(4)}",
        content_attributes: { is_private_reply: true }
      )
      Messages::StatusUpdateService.new(msg, 'failed', 'AI Generation Failed or not configured.').perform
      return
    end

    send_reply(comment_id, generated_text, reply_type)
  end

  private

  def supported_channel?
    SUPPORTED_CHANNELS.any? { |klass| @channel.is_a?(klass) }
  end

  def comment_too_old?(comment_id, comment_created_at)
    return false if comment_created_at.blank?

    created_time = Time.zone.at(comment_created_at.to_i)
    return false unless created_time < 7.days.ago

    Rails.logger.warn "[CommentReply] Skipping AI reply for #{comment_id} — comment older than 7 days"
    true
  rescue StandardError
    false
  end

  def send_reply(comment_id, text, reply_type)
    if @channel.is_a?(Channel::Tiktok)
      send_tiktok_comment_reply(comment_id, text)
    elsif reply_type == 'public'
      action_service_for_channel.reply_comment_and_log(comment_id, text, @conversation)
    else
      action_service_for_channel.send_private_reply_and_log(comment_id, text, @conversation)
    end
  end

  def action_service_for_channel
    if @channel.is_a?(Channel::FacebookPage)
      Facebook::CommentActionService.new(channel: @channel)
    else
      Instagram::CommentActionService.new(channel: @channel)
    end
  end

  def generate_reply_text(customer_message, post_id, platform, reply_type)
    Captain::Conversation::CommentReplyService.new(
      account: @conversation.account,
      conversation: @conversation,
      customer_message: customer_message,
      post_id: post_id,
      platform: platform,
      reply_type: reply_type
    ).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    nil
  end

  def send_tiktok_comment_reply(comment_id, text)
    client = Tiktok::Client.new(business_id: @channel.business_id, access_token: @channel.validated_access_token)
    reply_id = client.send_comment_reply(comment_id, text)

    return if reply_id.blank?

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: text,
      source_id: reply_id
    )
  rescue StandardError => e
    Rails.logger.error "[TikTok] Error sending AI comment reply for #{comment_id}: #{e.message}"
  end
end
