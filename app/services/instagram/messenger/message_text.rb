class Instagram::Messenger::MessageText < Instagram::BaseMessageText
  private

  def ensure_contact(ig_scope_id)
    result = fetch_instagram_user(ig_scope_id)
    find_or_create_contact(result) if result.present?
  end

  def fetch_instagram_user(ig_scope_id)
    if @inbox.facebook?
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token)
      k.get_object(ig_scope_id, fields: 'name,profile_pic') || {}
    else
      token = @inbox.channel.access_token
      api_version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
      url = "https://graph.instagram.com/#{api_version}/#{ig_scope_id}?fields=name,profile_picture_url&access_token=#{token}"
      response = HTTParty.get(url)
      
      return {} unless response.success?
      
      result = JSON.parse(response.body).with_indifferent_access
      {
        'name' => result['name'],
        'profile_pic' => result['profile_picture_url'] || result['profile_pic'],
        'id' => result['id']
      }.with_indifferent_access
    end
  rescue Koala::Facebook::AuthenticationError => e
    handle_authentication_error(e)
    {}
  rescue StandardError, Koala::Facebook::ClientError => e
    handle_client_error(e)
    {}
  end

  def handle_authentication_error(error)
    @inbox.channel.authorization_error!
    Rails.logger.warn("Authorization error for account #{@inbox.account_id} for inbox #{@inbox.id}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def handle_client_error(error)
    # Handle error code 230: User consent is required to access user profile
    # This typically occurs when the connected Instagram account attempts to send a message to a user
    # who has never messaged this Instagram account before.
    # We can safely ignore this error as per Facebook documentation.
    if error.message.include?('230')
      Rails.logger.warn error
      return
    end

    # Handle error code 9010: No matching Instagram user
    # This occurs when trying to fetch an Instagram user that doesn't exist or is not accessible
    # We can safely ignore this error and return empty result
    if error.message.include?('9010')
      Rails.logger.warn("[Instagram User Not Found]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
      Rails.logger.warn("[Instagram User Not Found]: #{error.message}")
      Rails.logger.warn("[Instagram User Not Found]: #{error}")
      return
    end

    Rails.logger.warn("[FacebookUserFetchClientError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[FacebookUserFetchClientError]: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end

  def create_message
    return unless @contact_inbox

    Messages::Instagram::Messenger::MessageBuilder.new(@messaging, @inbox, outgoing_echo: agent_message_via_echo?).perform
  end
end
