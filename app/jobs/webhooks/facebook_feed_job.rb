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
    message = change['message'] || ''
    sender_name = change['from']&.dig('name') || ''

    Rails.logger.info "[FacebookFeed] New comment on page #{page_id}: #{comment_id} from #{sender_name}"

    # 1. Handle comment hiding based on channel settings
    hide_comment_if_needed(channel, comment_id, message)

    # 2. Handle auto-reply via Private Replies API
    send_private_reply_if_needed(channel, comment_id)
  end

  private

  def hide_comment_if_needed(channel, comment_id, message)
    should_hide = channel.hide_comments?
    should_hide ||= channel.hide_phone_comments? && contains_phone?(message)
    should_hide ||= channel.hide_email_comments? && contains_email?(message)

    return unless should_hide

    Facebook::CommentActionService.new(channel: channel).hide_comment(comment_id)
  end

  def send_private_reply_if_needed(channel, comment_id)
    return unless channel.auto_reply_to_comments?
    return if channel.auto_reply_message.blank?

    Facebook::CommentActionService.new(channel: channel).send_private_reply(comment_id, channel.auto_reply_message)
  end

  def contains_phone?(text)
    # Matches Vietnamese phone numbers (09x, 08x, 07x, 03x, 05x, etc.) and international formats
    text.match?(/(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/)
  end

  def contains_email?(text)
    text.match?(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/)
  end
end
