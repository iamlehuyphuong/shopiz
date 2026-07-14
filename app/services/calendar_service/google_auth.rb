module CalendarService
  class GoogleAuth
    require 'net/http'
    require 'json'

    def initialize(calendar_integration)
      @calendar_integration = calendar_integration
    end

    def refresh_token!
      return unless @calendar_integration.provider == 'google'
      return unless @calendar_integration.refresh_token.present?

      # If the token is still valid for more than 5 minutes, do nothing
      return if @calendar_integration.expires_at && @calendar_integration.expires_at > 5.minutes.from_now

      uri = URI('https://oauth2.googleapis.com/token')
      response = Net::HTTP.post_form(uri, {
        'client_id' => ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', ''),
        'client_secret' => ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', ''),
        'refresh_token' => @calendar_integration.refresh_token,
        'grant_type' => 'refresh_token'
      })

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        @calendar_integration.update!(
          access_token: data['access_token'],
          expires_at: Time.current + data['expires_in'].to_i.seconds
        )
      else
        Rails.logger.error("Failed to refresh Google OAuth token for CalendarIntegration##{@calendar_integration.id}: #{response.body}")
      end
    end
  end
end
