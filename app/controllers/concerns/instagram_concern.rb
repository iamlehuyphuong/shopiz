module InstagramConcern
  extend ActiveSupport::Concern

  def instagram_client
    ::OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: 'https://api.instagram.com',
        authorize_url: 'https://api.instagram.com/oauth/authorize',
        token_url: 'https://api.instagram.com/oauth/access_token',
        auth_scheme: :request_body,
        token_method: :post
      }
    )
  end

  private

  def client_id
    GlobalConfigService.load('INSTAGRAM_APP_ID', nil)
  end

  def client_secret
    GlobalConfigService.load('INSTAGRAM_APP_SECRET', nil)
  end

  def exchange_for_long_lived_token(short_lived_token)
    # Official docs: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/business-login
    # Endpoint MUST be unversioned: https://graph.instagram.com/access_token
    # Method MUST be GET with query params
    endpoint = 'https://graph.instagram.com/access_token'
    params = {
      grant_type: 'ig_exchange_token',
      client_secret: client_secret,
      access_token: short_lived_token
    }

    Rails.logger.info "[Instagram] Exchanging short-lived token for long-lived token (token prefix: #{short_lived_token&.first(10)}...)"
    make_api_request(endpoint, params, 'Failed to exchange token', method: :get)
  end

  def fetch_instagram_user_details(access_token)
    endpoint = "https://graph.instagram.com/#{instagram_api_version}/me"
    params = {
      fields: 'id,user_id,username,name,profile_picture_url,account_type',
      access_token: access_token
    }

    parsed = make_api_request(endpoint, params, 'Failed to fetch Instagram user details')

    # Meta's /me endpoint sometimes returns the user object wrapped in a 'data' array
    parsed = parsed['data'].first if parsed.is_a?(Hash) && parsed['data'].is_a?(Array) && parsed['data'].any?

    parsed
  end

  # Fetches the Facebook Page ID linked to this Instagram professional account.
  # Required for Private Replies API: POST /{PAGE_ID}/messages
  # Uses the Instagram API to get connected Facebook Page info.
  def fetch_linked_page_id(access_token, instagram_user_id)
    endpoint = "https://graph.instagram.com/#{instagram_api_version}/#{instagram_user_id}"
    params = {
      fields: 'connected_facebook_page',
      access_token: access_token
    }

    result = make_api_request(endpoint, params, 'Failed to fetch linked Facebook Page')
    result.dig('connected_facebook_page', 'id')
  rescue StandardError => e
    Rails.logger.warn "[Instagram] Could not resolve linked page_id for #{instagram_user_id}: #{e.message}"
    nil
  end

  def make_api_request(endpoint, params, error_prefix, method: :get)
    options = { headers: { 'Accept' => 'application/json' }, timeout: 30 }

    if method == :post
      options[:body] = params
    else
      options[:query] = params
    end

    response = HTTParty.public_send(method, endpoint, options)

    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{error_prefix}: #{response.body}"
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      ChatwootExceptionTracker.new(e).capture_exception
      Rails.logger.error "Invalid JSON response: #{response.body}"
      raise e
    end
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def instagram_api_version
    GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
  end
end
