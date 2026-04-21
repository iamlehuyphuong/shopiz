# frozen_string_literal: true

class Webhooks::InstagramFeedJob < ApplicationJob
  queue_as :default

  def perform(entry_json)
    entry = JSON.parse(entry_json).with_indifferent_access

    instagram_id = entry[:id]
    channel = Channel::Instagram.find_by(instagram_id: instagram_id)
    return unless channel

    change = entry[:changes].first
    return unless change && change[:field] == 'comments'

    value = change[:value]
    comment_id = value[:id]
    post_id = value[:media][:id] if value[:media].present?
    post_id ||= 'unknown'
    message = value[:text] || ''
    comment_timestamp = value[:timestamp]

    sender_username = value.dig(:from, :username) || 'Instagram User'
    sender_id = value.dig(:from, :id) || "unknown_#{comment_id}"

    # Phase 3: Skip comments from our own Instagram account
    return if sender_id == instagram_id

    Rails.logger.info "[InstagramFeed] New comment on account #{instagram_id}: #{comment_id} from #{sender_username}"

    hide_comment_if_needed(channel, comment_id, message)

    conversation = Facebook::CommentHandlerService.new(
      channel: channel,
      contact_id: sender_id,
      contact_name: sender_username,
      comment_id: comment_id,
      post_id: post_id,
      message: message
    ).perform

    return unless conversation

    process_auto_reply(channel, conversation, comment_id, message, post_id, comment_timestamp)
  end

  private

  def hide_comment_if_needed(channel, comment_id, message)
    should_hide = channel.hide_comments?
    should_hide ||= channel.hide_phone_comments? && contains_phone?(message)
    should_hide ||= channel.hide_email_comments? && contains_email?(message)

    return unless should_hide

    Instagram::CommentActionService.new(channel: channel).hide_comment(comment_id)
  end

  def process_auto_reply(channel, conversation, comment_id, message, post_id, comment_timestamp)
    return unless channel.auto_reply_to_comments?

    # Phase 5: Check 7-day TTL — Meta requires private reply within 7 days of comment creation
    if comment_timestamp.present?
      comment_time = Time.at(comment_timestamp.to_i) rescue Time.current
      if comment_time < 7.days.ago
        Rails.logger.warn "[InstagramFeed] Skipping private reply for comment #{comment_id} — older than 7 days"
        return
      end
    end

    # Phase 4: Idempotency guard — only one private reply per comment
    lock_key = "private_reply:ig:#{comment_id}"
    return unless Redis::Alfred.setnx(lock_key, Time.current.to_i)

    Redis::Alfred.expire(lock_key, 7.days.to_i)

    if channel.provider_config['auto_reply_use_ai']
      Captain::Conversation::CommentReplyBuilderJob.perform_later(
        conversation.id,
        comment_id: comment_id,
        post_id: post_id,
        message: message,
        platform: 'instagram',
        comment_created_at: comment_timestamp.to_s
      )
    elsif channel.auto_reply_message.present?
      Instagram::CommentActionService.new(channel: channel).send_private_reply_and_log(
        comment_id,
        channel.auto_reply_message,
        conversation
      )
    end
  end

  def contains_phone?(text)
    text.match?(/(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/)
  end

  def contains_email?(text)
    text.match?(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/)
  end
end
