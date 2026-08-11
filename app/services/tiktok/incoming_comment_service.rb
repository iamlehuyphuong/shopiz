class Tiktok::IncomingCommentService
  include Tiktok::MessagingHelpers

  pattr_initialize [:channel!, :content!]

  def perform
    message = find_message(tt_conversation_id, tt_comment_id)
    return if message.present?

    new_message = create_message
    hide_comment_if_needed(new_message)
    process_auto_reply
  end

  private

  def contact_inbox
    # TikTok comments usually come from a specific user.
    # We will use the user_id as the source_id
    @contact_inbox ||= create_contact_inbox(channel, tt_user_id, tt_user_name, tt_user_id)
  end

  def contact
    contact_inbox.contact
  end

  def conversation
    @conversation ||= find_or_create_comment_conversation
  end

  def find_or_create_comment_conversation
    # For comments, we can group them by video_id
    conversation = contact_inbox.conversations.find_by(
      "additional_attributes->>'video_id' = ?", tt_video_id
    )

    return conversation if conversation.present?

    # Create new conversation
    Conversation.create!(
      account_id: channel.account_id,
      inbox_id: channel.inbox_id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: {
        type: 'comment',
        video_id: tt_video_id
      }
    )
  end

  def create_message
    message = conversation.messages.build(
      content: tt_comment_text,
      account_id: channel.inbox.account_id,
      inbox_id: channel.inbox.id,
      message_type: :incoming,
      content_attributes: message_content_attributes,
      source_id: tt_comment_id,
      created_at: tt_created_at,
      updated_at: tt_created_at
    )

    message.sender = contact
    message.save!
    message
  end

  def message_content_attributes
    attributes = {}
    attributes[:in_reply_to_external_id] = tt_reply_to_comment_id if tt_reply_to_comment_id.present?
    attributes
  end

  def tt_comment_id
    content[:comment_id] || content.dig(:comment, :id)
  end

  def tt_comment_text
    content[:text] || content.dig(:comment, :text)
  end

  def tt_conversation_id
    # We group by video_id generally, or you can consider the comment thread as conversation ID
    tt_video_id
  end

  def tt_video_id
    content[:video_id] || content.dig(:video, :id) || content[:item_id]
  end

  def tt_user_id
    content[:user_id] || content.dig(:user, :id) || content[:openid]
  end

  def tt_user_name
    content[:user_name] || content.dig(:user, :name) || 'TikTok User'
  end

  def tt_reply_to_comment_id
    content[:reply_to_comment_id] || content.dig(:comment, :reply_to_id)
  end

  def tt_created_at
    timestamp = content[:create_time] || content[:timestamp]
    return Time.current unless timestamp

    Time.zone.at(timestamp).utc
  end

  def process_auto_reply
    return unless channel.auto_reply_to_comments?
    return unless acquire_auto_reply_lock

    dispatch_auto_reply
  end

  def hide_comment_if_needed(message)
    should_hide = channel.hide_comments? ||
                  (channel.hide_phone_comments? && message.content.match?(/\b\d{9,11}\b/)) ||
                  (channel.hide_email_comments? && message.content.match?(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/))

    return unless should_hide

    client = Tiktok::Client.new(business_id: channel.business_id, access_token: channel.validated_access_token)
    client.hide_comment(tt_video_id, tt_comment_id)
  rescue StandardError => e
    Rails.logger.error "[TikTok] Error hiding comment #{tt_comment_id}: #{e.message}"
  end

  def acquire_auto_reply_lock
    lock_key = "auto_reply:tt:#{channel.id}:#{tt_comment_id}"
    return false unless Redis::Alfred.setnx(lock_key, Time.current.to_i)

    Redis::Alfred.expire(lock_key, 7.days.to_i)
    true
  end

  def dispatch_auto_reply
    if channel.auto_reply_use_ai?
      Captain::Conversation::CommentReplyBuilderJob.perform_later(
        conversation.id,
        comment_id: tt_comment_id,
        post_id: tt_video_id,
        message: tt_comment_text,
        platform: 'tiktok',
        comment_created_at: tt_created_at.to_s
      )
    elsif channel.auto_reply_message.present?
      processed_message = process_liquid_message(channel.auto_reply_message, conversation)
      send_comment_auto_reply(tt_comment_id, processed_message)
    end
  end

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

  def send_comment_auto_reply(comment_id, reply_text)
    client = Tiktok::Client.new(business_id: channel.business_id, access_token: channel.validated_access_token)
    reply_id = client.send_comment_reply(comment_id, reply_text)

    return if reply_id.blank?

    conversation.messages.create!(
      account_id: channel.account_id,
      inbox_id: channel.inbox_id,
      message_type: :activity,
      content: "Public comment: #{reply_text}",
      source_id: reply_id
    )
  rescue StandardError => e
    Rails.logger.error "[TikTok] Error sending auto-reply for comment #{comment_id}: #{e.message}"
  end
end
