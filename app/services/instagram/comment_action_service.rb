# frozen_string_literal: true

# Service to interact with Instagram Graph API for comment management on posts/reels.
# Handles hiding comments and sending private replies.
class Instagram::CommentActionService
  API_VERSION = 'v22.0'

  def initialize(channel:)
    @channel = channel
    @access_token = channel.access_token
    @instagram_id = channel.instagram_id
  end

  # Hide a comment on a post
  # POST /{comment_id}?hide=true
  def hide_comment(comment_id)
    url = "https://graph.instagram.com/#{API_VERSION}/#{comment_id}"
    response = HTTParty.post(url, body: { hide: true, access_token: @access_token })

    if response.success?
      Rails.logger.info "[InstagramFeed] Successfully hid comment #{comment_id}"
    else
      Rails.logger.error "[InstagramFeed] Failed to hide comment #{comment_id}: #{response.body}"
    end

    response
  rescue StandardError => e
    Rails.logger.error "[InstagramFeed] Error hiding comment #{comment_id}: #{e.message}"
    nil
  end

  # Send a private reply to a comment via Instagram Direct
  # POST /{ig_user_id}/messages
  def send_private_reply(comment_id, message_text)
    url = "https://graph.instagram.com/#{API_VERSION}/#{@instagram_id}/messages"
    payload = {
      recipient: { comment_id: comment_id },
      message: { text: message_text },
      access_token: @access_token
    }
    
    response = HTTParty.post(
      url, 
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      Rails.logger.info "[InstagramFeed] Successfully sent private reply for comment #{comment_id}"
    else
      Rails.logger.error "[InstagramFeed] Failed to send private reply for comment #{comment_id}: #{response.body}"
    end

    response
  rescue StandardError => e
    Rails.logger.error "[InstagramFeed] Error sending private reply for comment #{comment_id}: #{e.message}"
    nil
  end

  def send_private_reply_and_log(comment_id, message_text, conversation)
    response = send_private_reply(comment_id, message_text)
    return unless response&.success?

    body = JSON.parse(response.body)
    msg_id = body['message_id'] || body['id']

    return unless msg_id.present?

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: message_text,
      source_id: msg_id
    )
  end
end
