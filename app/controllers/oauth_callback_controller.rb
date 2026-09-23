class OauthCallbackController < ApplicationController
  def show
    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback"
    )

    handle_response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to '/'
  end

  private

  def handle_response
    raise NotImplementedError
  end

  def provider_name
    raise NotImplementedError
  end

  def oauth_client
    raise NotImplementedError
  end

  def account_from_signed_id
    raise ActionController::BadRequest, 'Missing state variable' if params[:state].blank?

    account = GlobalID::Locator.locate_signed(params[:state])
    raise 'Invalid or expired state' if account.nil?

    account
  end

  def account
    @account ||= account_from_signed_id
  end

  def oauth_code
    params[:code]
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end
end
