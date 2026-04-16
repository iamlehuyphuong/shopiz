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
    message = value[:text] || ''
    sender_username = value.dig(:from, :username) || ''

    Rails.logger.info "[InstagramFeed] New comment on account #{instagram_id}: #{comment_id} from #{sender_username}"

    hide_comment_if_needed(channel, comment_id, message)
    send_private_reply_if_needed(channel, comment_id)
  end

  private

  def hide_comment_if_needed(channel, comment_id, message)
    should_hide = channel.hide_comments?
    should_hide ||= channel.hide_phone_comments? && contains_phone?(message)
    should_hide ||= channel.hide_email_comments? && contains_email?(message)

    return unless should_hide

    Instagram::CommentActionService.new(channel: channel).hide_comment(comment_id)
  end

  def send_private_reply_if_needed(channel, comment_id)
    return unless channel.auto_reply_to_comments?
    return if channel.auto_reply_message.blank?

    Instagram::CommentActionService.new(channel: channel).send_private_reply(comment_id, channel.auto_reply_message)
  end

  def contains_phone?(text)
    text.match?(/(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/)
  end

  def contains_email?(text)
    text.match?(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/)
  end
end
