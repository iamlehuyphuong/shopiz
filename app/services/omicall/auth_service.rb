class Omicall::AuthService
  API_URL = 'https://api.omicall.com/omicall-api/authentication'.freeze

  def initialize(account)
    @account = account
  end

  def access_token
    Rails.cache.fetch(cache_key, expires_in: 23.hours, skip_nil: true) do
      fetch_new_token
    end
  end

  private

  def fetch_new_token
    return nil unless api_key

    response = HTTParty.get(API_URL, query: { apiKey: api_key })
    
    if response.success? && response.parsed_response['status_code'] == 9999
      token = response.parsed_response.dig('payload', 'access_token')
      token
    else
      Rails.logger.error "OmiCall Auth Error: #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "OmiCall Auth Exception: #{e.message}"
    nil
  end

  def api_key
    hook = @account.hooks.find_by(app_id: 'omicall')
    hook&.settings&.dig('api_key')
  end

  def cache_key
    "omicall_access_token_#{@account.id}"
  end
end
