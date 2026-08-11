# frozen_string_literal: true

# Service to interact with Facebook Graph API for comment management on posts.
# Handles hiding comments and sending private replies.
class Facebook::CommentActionService
  API_VERSION = 'v25.0'

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
  # POST /{PAGE_ID}/messages — using the official Send API endpoint
  # Ref: https://developers.facebook.com/docs/messenger-platform/discovery/private-replies
  def send_private_reply(comment_id, message)
    url = "https://graph.facebook.com/#{API_VERSION}/#{@channel.page_id}/messages"
    payload = {
      recipient: { comment_id: comment_id },
      message: { text: message }
    }

    response = HTTParty.post(
      url,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      query: { access_token: @access_token }
    )

    if response.success?
      Rails.logger.info "[FacebookFeed] Successfully sent private reply for comment #{comment_id}"
    else
      log_api_error('send private reply', comment_id, response)
    end

    response
  rescue StandardError => e
    Rails.logger.error "[FacebookFeed] Error sending private reply for comment #{comment_id}: #{e.message}"
    nil
  end

  def send_private_reply_and_log(comment_id, message, conversation)
    response = send_private_reply(comment_id, message)
    
    if response&.success?
      # Facebook returns `{"recipient_id":"...","message_id":"m_1234abc..."}` for the generated private reply
      body = JSON.parse(response.body)
      msg_id = body['message_id'] || body['id']

      return unless msg_id.present?

      conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :outgoing,
        content: message,
        source_id: msg_id,
        content_attributes: { is_private_reply: true }
      )
    else
      body = JSON.parse(response.body) rescue {}
      error_msg = body.dig('error', 'message') || 'Failed to send private reply'
      
      msg = conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :outgoing,
        content: message,
        status: :failed,
        source_id: "failed_fb_#{SecureRandom.hex(4)}",
        content_attributes: { is_private_reply: true }
      )
      Messages::StatusUpdateService.new(msg, 'failed', error_msg).perform
    end
  end

  # Send a public reply to a Facebook comment
  # POST /{comment_id}/comments
  def reply_comment(comment_id, message)
    url = "https://graph.facebook.com/#{API_VERSION}/#{comment_id}/comments"
    response = HTTParty.post(
      url,
      body: { message: message, access_token: @access_token }
    )

    if response.success?
      Rails.logger.info "[FacebookFeed] Successfully replied publicly to comment #{comment_id}"
    else
      log_api_error('reply comment', comment_id, response)
    end

    response
  rescue StandardError => e
    Rails.logger.error "[FacebookFeed] Error replying to comment #{comment_id}: #{e.message}"
    nil
  end

  def reply_comment_and_log(comment_id, message, conversation)
    response = reply_comment(comment_id, message)
    
    if response&.success?
      body = JSON.parse(response.body)
      msg_id = body['id']

      return unless msg_id.present?

      conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: @channel.inbox_id,
        message_type: :activity,
        content: I18n.t('errors.facebook.comment_handler.public_comment', text: message),
        source_id: msg_id
      )
    else
      body = JSON.parse(response.body) rescue {}
      error_msg = body.dig('error', 'message') || 'Failed to send public reply'
      
      msg = conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: "Public comment: #{message}",
        status: :failed,
        source_id: "failed_fb_reply_#{SecureRandom.hex(4)}"
      )
      Messages::StatusUpdateService.new(msg, 'failed', error_msg).perform
    end
  end

  private

  def log_api_error(action, comment_id, response)
    body = JSON.parse(response.body) rescue {}
    error_code = body.dig('error', 'code')
    error_msg = body.dig('error', 'message') || response.body

    case error_code
    when 10
      Rails.logger.warn "[FacebookFeed] Rate limited while #{action} for comment #{comment_id}"
    when 200, 551
      # "Only one message can be sent" — already replied, treat as idempotent success
      Rails.logger.info "[FacebookFeed] Private reply already sent for comment #{comment_id} (code #{error_code})"
    when 100
      Rails.logger.warn "[FacebookFeed] Invalid request for #{action} comment #{comment_id}: #{error_msg}"
    else
      Rails.logger.error "[FacebookFeed] Failed to #{action} for comment #{comment_id} (code #{error_code}): #{error_msg}"
    end
  end
end
