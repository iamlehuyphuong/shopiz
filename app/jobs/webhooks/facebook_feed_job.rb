# frozen_string_literal: true

class Webhooks::FacebookFeedJob < ApplicationJob
  queue_as :default

  # @param page_id [String] Facebook page ID
  # @param change_json [String] JSON string of the feed change value
  def perform(page_id, change_json)
    change = JSON.parse(change_json)

    # A single page_id can be connected to multiple accounts — process each independently
    channels = Channel::FacebookPage.where(page_id: page_id)
    return if channels.empty?

    comment_data = extract_comment_data(change)

    # Skip comments from the Page itself — cannot send private reply to self
    return if comment_data[:sender_id] == page_id

    Rails.logger.info "[FacebookFeed] New comment on page #{page_id}: #{comment_data[:comment_id]} from #{comment_data[:sender_name]}"

    channels.each do |channel|
      process_comment_for_channel(channel, comment_data)
    rescue StandardError => e
      Rails.logger.error "[FacebookFeed] Error processing comment for channel #{channel.id} (account #{channel.account_id}): #{e.message}"
    end
  end

  private

  def extract_comment_data(change)
    {
      comment_id: change['comment_id'],
      post_id: change['post_id'],
      message: change['message'] || '',
      created_time: change['created_time'],
      sender_name: change.dig('from', 'name') || 'Facebook User',
      sender_id: change.dig('from', 'id') || "unknown_#{change['comment_id']}"
    }
  end

  def process_comment_for_channel(channel, data)
    comment_hidden = hide_comment_if_needed(channel, data[:comment_id], data[:message])

    conversation = build_conversation(channel, data, comment_hidden: comment_hidden)
    return unless conversation

    process_auto_reply(channel, conversation, data)
  end

  def build_conversation(channel, data, comment_hidden: false)
    Facebook::CommentHandlerService.new(
      channel: channel,
      contact_id: data[:sender_id],
      contact_name: data[:sender_name],
      comment_id: data[:comment_id],
      post_id: data[:post_id],
      message: data[:message],
      comment_hidden: comment_hidden
    ).perform
  end

  def hide_comment_if_needed(channel, comment_id, message)
    should_hide = channel.hide_comments?
    should_hide ||= channel.hide_phone_comments? && contains_phone?(message)
    should_hide ||= channel.hide_email_comments? && contains_email?(message)

    return false unless should_hide

    Facebook::CommentActionService.new(channel: channel).hide_comment(comment_id)
    true
  end

  # rubocop:disable Metrics/MethodLength
  def process_auto_reply(channel, conversation, data)
    return unless channel.auto_reply_to_comments?
    return if comment_too_old?(data)

    # Idempotency guard — one private reply per comment per channel
    lock_key = "private_reply:fb:#{channel.id}:#{data[:comment_id]}"
    return unless Redis::Alfred.setnx(lock_key, Time.current.to_i)

    Redis::Alfred.expire(lock_key, 7.days.to_i)

    if channel.provider_config['auto_reply_use_ai']
      Captain::Conversation::CommentReplyBuilderJob.perform_later(
        conversation.id,
        comment_id: data[:comment_id],
        post_id: data[:post_id],
        message: data[:message],
        platform: 'facebook',
        comment_created_at: data[:created_time].to_s
      )
    elsif channel.auto_reply_message.present?
      Facebook::CommentActionService.new(channel: channel).send_private_reply_and_log(
        data[:comment_id],
        channel.auto_reply_message,
        conversation
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def comment_too_old?(data)
    return false if data[:created_time].blank?

    comment_time = Time.zone.at(data[:created_time].to_i)
    if comment_time < 7.days.ago
      Rails.logger.warn "[FacebookFeed] Skipping private reply for comment #{data[:comment_id]} — older than 7 days"
      return true
    end

    false
  end

  def contains_phone?(text)
    text.match?(/(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/)
  end

  def contains_email?(text)
    text.match?(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/)
  end
end
