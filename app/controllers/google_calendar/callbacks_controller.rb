class GoogleCalendar::CallbacksController < OauthCallbackController
  def show
    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback"
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error e
    redirect_to frontend_url("/app/accounts/#{account.id}/sales/tools/google_calendar")
  end

  private

  def handle_response
    email = get_user_email(parsed_body['access_token'])

    @integration = account.calendar_integrations.find_or_initialize_by(provider: 'google')
    @integration.assign_attributes(
      access_token: parsed_body['access_token'],
      refresh_token: parsed_body['refresh_token'] || @integration.refresh_token,
      expires_at: Time.current + parsed_body['expires_in'].to_i.seconds,
      email: email
    )
    
    @integration.save!

    redirect_to frontend_url("/app/accounts/#{account.id}/sales/tools/google_calendar")
  end

  def get_user_email(access_token)
    response = Net::HTTP.get_response(URI("https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{access_token}"))
    parsed_response = JSON.parse(response.body)
    parsed_response['email']
  rescue StandardError => e
    Rails.logger.error "Failed to get user email from Google: #{e.message}"
    nil
  end

  def frontend_url(path)
    "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}#{path}"
  end

  def provider_name
    'google_calendar'
  end

  def oauth_client
    app_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    app_secret = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil)

    ::OAuth2::Client.new(app_id, app_secret, {
                           site: 'https://oauth2.googleapis.com',
                           authorize_url: 'https://accounts.google.com/o/oauth2/auth',
                           token_url: 'https://accounts.google.com/o/oauth2/token'
                         })
  end
end
