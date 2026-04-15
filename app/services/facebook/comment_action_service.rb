# frozen_string_literal: true

# Service to interact with Facebook Graph API for comment management on posts.
# Handles hiding comments and sending private replies.
class Facebook::CommentActionService
  API_VERSION = 'v18.0'

  def initialize(channel:)
    @channel = channel
    @access_token = channel.page_access_token
  end

  # Hide a comment on a post
  # POST /{comment_id}?is_hidden=true
  def hide_comment(comment_id)
    url = "https://graph.facebook.com/#{API_VERSION}/#{comment_id}"
    response = HTTParty.post(url, body: { is_hidden: true, access_token: @access_token })

    if response.success?
      Rails.logger.info "[FacebookFeed] Successfully hid comment #{comment_id}"
    else
      Rails.logger.error "[FacebookFeed] Failed to hide comment #{comment_id}: #{response.body}"
    end

    response
  rescue StandardError => e
    Rails.logger.error "[FacebookFeed] Error hiding comment #{comment_id}: #{e.message}"
    nil
  end

  # Send a private reply to a comment via Messenger
  # POST /{comment_id}/private_replies
  def send_private_reply(comment_id, message)
    url = "https://graph.facebook.com/#{API_VERSION}/#{comment_id}/private_replies"
    response = HTTParty.post(url, body: { message: message, access_token: @access_token })

    if response.success?
      Rails.logger.info "[FacebookFeed] Successfully sent private reply for comment #{comment_id}"
    else
      Rails.logger.error "[FacebookFeed] Failed to send private reply for comment #{comment_id}: #{response.body}"
    end

    response
  rescue StandardError => e
    Rails.logger.error "[FacebookFeed] Error sending private reply for comment #{comment_id}: #{e.message}"
    nil
  end
end
