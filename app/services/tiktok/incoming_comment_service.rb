class Tiktok::IncomingCommentService
  include Tiktok::MessagingHelpers

  pattr_initialize [:channel!, :content!]

  def perform
    message = find_message(tt_conversation_id, tt_comment_id)
    return if message.present?

    create_message
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
end
