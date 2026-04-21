# frozen_string_literal: true

class Webhooks::FacebookFeedJob < ApplicationJob
  queue_as :default

  # @param page_id [String] Facebook page ID
  # @param change_json [String] JSON string of the feed change value
  def perform(page_id, change_json)
    change = JSON.parse(change_json)
    channel = Channel::FacebookPage.find_by(page_id: page_id)
    return unless channel

    comment_id = change['comment_id']
    post_id = change['post_id']
    message = change['message'] || ''
    comment_created_time = change['created_time']

    # Facebook user from feed
    sender_name = change['from']&.dig('name') || 'Facebook User'
    sender_id = change['from']&.dig('id') || "unknown_#{comment_id}"

    # Phase 3: Skip comments from the Page itself — cannot send private reply to self
    return if sender_id == page_id

    Rails.logger.info "[FacebookFeed] New comment on page #{page_id}: #{comment_id} from #{sender_name}"

    # 1. Handle comment hiding based on channel settings
    hide_comment_if_needed(channel, comment_id, message)

    # 2. Build discussion Context (Internal Note)
    conversation = Facebook::CommentHandlerService.new(
      channel: channel,
      contact_id: sender_id,
      contact_name: sender_name,
      comment_id: comment_id,
      post_id: post_id,
      message: message
    ).perform

    return unless conversation

    # 3. Handle auto-reply (DM)
    process_auto_reply(channel, conversation, comment_id, message, post_id, comment_created_time)
  end

  private

  def hide_comment_if_needed(channel, comment_id, message)
    should_hide = channel.hide_comments?
    should_hide ||= channel.hide_phone_comments? && contains_phone?(message)
    should_hide ||= channel.hide_email_comments? && contains_email?(message)

    return unless should_hide

    Facebook::CommentActionService.new(channel: channel).hide_comment(comment_id)
  end

  def process_auto_reply(channel, conversation, comment_id, message, post_id, comment_created_time)
    # config setup can be in provider_config or auto_reply_to_comments flag directly.
    return unless channel.auto_reply_to_comments?

    # Phase 5: Check 7-day TTL — Meta requires private reply within 7 days of comment creation
    if comment_created_time.present?
      comment_time = Time.at(comment_created_time.to_i)
      if comment_time < 7.days.ago
        Rails.logger.warn "[FacebookFeed] Skipping private reply for comment #{comment_id} — older than 7 days"
        return
      end
    end

    # Phase 4: Idempotency guard — only one private reply per comment
    lock_key = "private_reply:fb:#{comment_id}"
    return unless Redis::Alfred.setnx(lock_key, Time.current.to_i)

    Redis::Alfred.expire(lock_key, 7.days.to_i)

    if channel.provider_config['auto_reply_use_ai']
      # Call the AI Builder
      Captain::Conversation::CommentReplyBuilderJob.perform_later(
        conversation.id,
        comment_id: comment_id,
        post_id: post_id,
        message: message,
        platform: 'facebook',
        comment_created_at: comment_created_time.to_s
      )
    elsif channel.auto_reply_message.present?
      # Send static message
      Facebook::CommentActionService.new(channel: channel).send_private_reply_and_log(
        comment_id,
        channel.auto_reply_message,
        conversation
      )
    end
  end

  def contains_phone?(text)
    # Matches Vietnamese phone numbers (09x, 08x, 07x, 03x, 05x, etc.) and international formats
    text.match?(/(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/)
  end

  def contains_email?(text)
    text.match?(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/)
  end
end
