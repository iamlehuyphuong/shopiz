class Api::V1::Accounts::Integrations::GoogleCalendar::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  def create
    app_id = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
    app_secret = GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil)

    client = ::OAuth2::Client.new(app_id, app_secret, {
                                    site: 'https://oauth2.googleapis.com',
                                    authorize_url: 'https://accounts.google.com/o/oauth2/auth',
                                    token_url: 'https://accounts.google.com/o/oauth2/token'
                                  })

    redirect_url = client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/google_calendar/callback",
        scope: 'email profile https://www.googleapis.com/auth/calendar',
        response_type: 'code',
        prompt: 'consent',
        access_type: 'offline',
        state: state,
        client_id: app_id
      }
    )

    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end
end
