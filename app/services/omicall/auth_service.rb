class Omicall::AuthService
  API_URL = "#{ENV.fetch('OMICALL_API_URL', 'https://public-v1-stg.omicall.com')}/api/auth".freeze

  def initialize(account, api_key: nil)
    @account = account
    @provided_api_key = api_key
  end

  def access_token
    Rails.cache.fetch(cache_key, expires_in: 23.hours, skip_nil: true) do
      fetch_new_token
    end
  end

  def api_key
    return @provided_api_key if @provided_api_key.present?

    hook = @account.hooks.find_by(app_id: 'omicall')
    hook&.hook_api_key
  end

  private

  def fetch_new_token
    return nil unless api_key

    response = HTTParty.get(API_URL, query: { apiKey: api_key })

    if response.success? && response.parsed_response['status_code'] == 9999
      response.parsed_response.dig('payload', 'access_token')

    else
      Rails.logger.error "OmiCall Auth Error: #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "OmiCall Auth Exception: #{e.message}"
    nil
  end

  def cache_key
    "omicall_access_token_#{@account.id}"
  end
end
