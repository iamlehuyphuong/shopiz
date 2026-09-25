class Instagram::SendOnInstagramService < Instagram::BaseSendService
  private

  def channel_class
    Channel::Instagram
  end

  # Deliver a message with the given payload.
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_message(message_content)
    return handle_comment_reply(message_content) if message_content.dig(:recipient, :comment_id).present?

    access_token = channel.access_token
    query = { access_token: access_token }
    instagram_id = channel.instagram_id.presence || 'me'

    response = HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{instagram_id}/messages",
      body: message_content,
      query: query
    )

    process_response(response, message_content)
  end

  def handle_comment_reply(message_content)
    response = Instagram::CommentActionService.new(channel: channel).send_private_reply(
      message_content.dig(:recipient, :comment_id),
      message_content[:message]
    )

    if response&.success?
      message.update!(content_attributes: message.content_attributes.merge(is_private_reply: true).except('target_comment_id'))
      conversation.update!(additional_attributes: conversation.additional_attributes.except('comment_id'))
    end

    process_response(response, message_content) if response
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    return params unless global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']

    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'HUMAN_AGENT'
    params
  end
end
