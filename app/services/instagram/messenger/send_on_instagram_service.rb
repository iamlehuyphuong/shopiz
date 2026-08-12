class Instagram::Messenger::SendOnInstagramService < Instagram::BaseSendService
  private

  def channel_class
    Channel::FacebookPage
  end

  # Deliver a message with the given payload.
  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/send-message
  def send_message(message_content)
    if message_content.dig(:recipient, :comment_id).present?
      return handle_comment_reply(message_content)
    end

    access_token = channel.page_access_token
    api_version = GlobalConfigService.load('FACEBOOK_API_VERSION', '25.0')
    app_secret_proof = calculate_app_secret_proof(GlobalConfigService.load('FB_APP_SECRET', ''), access_token)
    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof

    response = HTTParty.post(
      "https://graph.facebook.com/v#{api_version}/me/messages",
      body: message_content,
      query: query
    )

    process_response(response, message_content)
  end

  def handle_comment_reply(message_content)
    response = Instagram::CommentActionService.new(channel: channel).send_private_reply(
      message_content.dig(:recipient, :comment_id),
      message_content.dig(:message, :text)
    )

    if response&.success?
      message.update!(content_attributes: message.content_attributes.merge(is_private_reply: true).except('target_comment_id'))
      conversation.update!(additional_attributes: conversation.additional_attributes.except('comment_id'))
    end

    process_response(response, message_content) if response
  end

  def calculate_app_secret_proof(app_secret, access_token)
    Facebook::Messenger::Configuration::AppSecretProofCalculator.call(
      app_secret, access_token
    )
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')

    return params unless global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']

    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'HUMAN_AGENT'
    params
  end
end
