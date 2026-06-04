# frozen_string_literal: true

class Webhooks::InstagramFeedJob < ApplicationJob
  queue_as :default

  def perform(entry_json)
    entry = JSON.parse(entry_json).with_indifferent_access

    instagram_id = entry[:id]

    # A single instagram_id can be connected to multiple accounts — process each independently
    channels = Channel::Instagram.where(instagram_id: instagram_id)
    return if channels.empty?

    change = entry[:changes].first
    return unless change && change[:field] == 'comments'

    comment_data = extract_comment_data(change[:value])

    # Skip comments from our own Instagram account
    return if comment_data[:sender_id] == instagram_id

    Rails.logger.info "[InstagramFeed] New comment on account #{instagram_id}: #{comment_data[:comment_id]} from #{comment_data[:sender_name]}"

    channels.each do |channel|
      process_comment_for_channel(channel, comment_data)
    rescue StandardError => e
      Rails.logger.error "[InstagramFeed] Error processing comment for channel #{channel.id} (account #{channel.account_id}): #{e.message}"
    end
  end

  private

  def extract_comment_data(value)
    {
      comment_id: value[:id],
      post_id: value.dig(:media, :id) || 'unknown',
      message: value[:text] || '',
      created_time: value[:timestamp],
      sender_name: value.dig(:from, :username) || 'Instagram User',
      sender_id: value.dig(:from, :id) || "unknown_#{value[:id]}"
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

    Instagram::CommentActionService.new(channel: channel).hide_comment(comment_id)
    true
  end

  # rubocop:disable Metrics/MethodLength
  def process_auto_reply(channel, conversation, data)
    return unless channel.auto_reply_to_comments?
    return if comment_too_old?(data)

    # Idempotency guard — one private reply per comment per channel
    lock_key = "private_reply:ig:#{channel.id}:#{data[:comment_id]}"
    return unless Redis::Alfred.setnx(lock_key, Time.current.to_i)

    Redis::Alfred.expire(lock_key, 7.days.to_i)

    if channel.provider_config['auto_reply_use_ai']
      Captain::Conversation::CommentReplyBuilderJob.perform_later(
        conversation.id,
        comment_id: data[:comment_id],
        post_id: data[:post_id],
        message: data[:message],
        platform: 'instagram',
        comment_created_at: data[:created_time].to_s
      )
    elsif channel.auto_reply_message.present?
      processed_message = process_liquid_message(channel.auto_reply_message, conversation)
      Instagram::CommentActionService.new(channel: channel).send_private_reply_and_log(
        data[:comment_id],
        processed_message,
        conversation
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def process_liquid_message(message, conversation)
    return message if message.blank?

    template = Liquid::Template.parse(message)
    template.render({
      'contact' => ContactDrop.new(conversation.contact),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(conversation.inbox),
      'account' => AccountDrop.new(conversation.account)
    })
  rescue Liquid::Error
    message
  end

  def comment_too_old?(data)
    return false if data[:created_time].blank?

    comment_time = Time.zone.at(data[:created_time].to_i)
    if comment_time < 7.days.ago
      Rails.logger.warn "[InstagramFeed] Skipping private reply for comment #{data[:comment_id]} — older than 7 days"
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
