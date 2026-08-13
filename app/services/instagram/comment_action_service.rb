# frozen_string_literal: true

# Service to interact with Instagram Graph API for comment management on posts/reels.
# Handles hiding comments and sending private replies.
class Instagram::CommentActionService
  def self.api_version
    GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
  end

  def initialize(channel:)
    @channel = channel
    @access_token = channel.access_token
    @instagram_id = channel.instagram_id
  end

  # Hide a comment on a post
  # POST /{comment_id}?hide=true
  def hide_comment(comment_id)
    url = "https://graph.instagram.com/#{self.class.api_version}/#{comment_id}"
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
  # POST /{PAGE_ID}/messages — using Facebook Send API
  # Ref: https://developers.facebook.com/docs/messenger-platform/instagram/features/private-replies
  # Private replies require a Page Access Token, which the Instagram channel doesn't have.
  # Delegate to the linked Facebook Page if it exists.
  def send_private_reply(comment_id, message_text)
    facebook_page = Channel::FacebookPage.find_by(instagram_id: @instagram_id, account_id: @channel.account_id)

    unless facebook_page
      Rails.logger.warn "[InstagramFeed] No linked Facebook Page found for private reply on comment #{comment_id}"
      error_message = 'Meta API does not support Private Replies for Instagram Login without a linked Facebook Page'
      return OpenStruct.new(
        success?: false,
        body: { error: { message: error_message } }.to_json,
        parsed_response: { 'error' => { 'message' => error_message } }
      )
    end

    # Delegate to Facebook's CommentActionService using Page Access Token
    Facebook::CommentActionService.new(channel: facebook_page).send_private_reply(comment_id, message_text)
  end

  def send_private_reply_and_log(comment_id, message_text, conversation)
    response = send_private_reply(comment_id, message_text)

    if response&.success?
      body = JSON.parse(response.body)
      msg_id = body['message_id'] || body['id']

      return unless msg_id.present?

      conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :outgoing,
        content: message_text,
        source_id: msg_id,
        content_attributes: { is_private_reply: true }
      )
    else
      body = begin
        JSON.parse(response.body)
      rescue StandardError
        {}
      end
      error_msg = body.dig('error', 'message') || 'Failed to send private reply'

      msg = conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :outgoing,
        content: message_text,
        status: :failed,
        source_id: "failed_ig_#{SecureRandom.hex(4)}",
        content_attributes: { is_private_reply: true }
      )
      Messages::StatusUpdateService.new(msg, 'failed', error_msg).perform
    end
  end

  # Send a public reply to an Instagram comment
  # POST /{ig_comment_id}/replies
  def reply_comment(comment_id, message_text)
    url = "https://graph.instagram.com/#{self.class.api_version}/#{comment_id}/replies"
    response = HTTParty.post(
      url,
      body: { message: message_text, access_token: @access_token }
    )

    if response.success?
      Rails.logger.info "[InstagramFeed] Successfully replied publicly to comment #{comment_id}"
    else
      log_api_error('reply comment', comment_id, response)
    end

    response
  rescue StandardError => e
    Rails.logger.error "[InstagramFeed] Error replying to comment #{comment_id}: #{e.message}"
    nil
  end

  def reply_comment_and_log(comment_id, message_text, conversation)
    response = reply_comment(comment_id, message_text)

    if response&.success?
      body = JSON.parse(response.body)
      msg_id = body['id']

      return unless msg_id.present?

      conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: I18n.t('errors.facebook.comment_handler.public_comment', text: message_text),
        source_id: msg_id
      )
    else
      body = begin
        JSON.parse(response.body)
      rescue StandardError
        {}
      end
      error_msg = body.dig('error', 'message') || 'Failed to send public reply'

      msg = conversation.messages.create!(
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: I18n.t('errors.facebook.comment_handler.public_comment', text: message_text),
        status: :failed,
        source_id: "failed_ig_reply_#{SecureRandom.hex(4)}"
      )
      Messages::StatusUpdateService.new(msg, 'failed', error_msg).perform
    end
  end

  private

  def log_api_error(action, comment_id, response)
    body = begin
      JSON.parse(response.body)
    rescue StandardError
      {}
    end
    error_code = body.dig('error', 'code')
    error_msg = body.dig('error', 'message') || response.body

    case error_code
    when 10
      Rails.logger.warn "[InstagramFeed] Rate limited while #{action} for comment #{comment_id}"
    when 200, 551
      Rails.logger.info "[InstagramFeed] Private reply already sent for comment #{comment_id} (code #{error_code})"
    when 100
      Rails.logger.warn "[InstagramFeed] Invalid request for #{action} comment #{comment_id}: #{error_msg}"
    else
      Rails.logger.error "[InstagramFeed] Failed to #{action} for comment #{comment_id} (code #{error_code}): #{error_msg}"
    end
  end
end
