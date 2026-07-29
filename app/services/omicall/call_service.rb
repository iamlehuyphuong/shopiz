class Omicall::CallService
  API_BASE_URL = ENV.fetch('OMICALL_API_URL', 'https://public-v1-stg.omicall.com').freeze

  def initialize(account, api_key: nil)
    @account = account
    @auth_service = Omicall::AuthService.new(account, api_key: api_key)
  end

  def click2call(extension:, hotline:, phone_number:)
    endpoint = "#{API_BASE_URL}/api/click2call"
    body = {
      extension: extension,
      hotline: hotline,
      phone_number: phone_number
    }

    make_request(:post, endpoint, body: body.to_json)
  end

  def internal_phones
    endpoint = "#{API_BASE_URL}/api/call_center/internal_phone/list"
    make_request(:get, endpoint)
  end

  def request_callbot(contacts:, sip_numbers:, script_id:, session_name:, voice: 'northern_female_ngocanh')
    endpoint = "#{API_BASE_URL}/omicall-api/v2/call-bot/request"
    body = {
      contacts: contacts,
      sipNumbers: sip_numbers,
      scriptId: script_id,
      sessionName: session_name,
      voice: voice,
      callbackResultConfig: {
        url: webhook_url
      }
    }

    make_request(:post, endpoint, body: body.to_json)
  end

  def call_history(phone_number: nil, page: 1, size: 50)
    endpoint = "#{API_BASE_URL}/api/v3/call-transaction/search?page=#{page}&size=#{size}"

    # 1 month limit by OMiCall (prevents date_is_too_long error)
    to_date = Time.current.to_i * 1000
    from_date = 1.month.ago.to_i * 1000

    body = {
      filter: {
        fromDate: from_date,
        toDate: to_date
      },
      sort: {
        field: 'created_date',
        isAsc: false
      }
    }

    if phone_number.present?
      normalized_phone = phone_number.sub(/^\+84/, '0')
      body[:filter][:phoneNumbers] = [normalized_phone]
    end

    # API v3 requires x-api-key directly, bypassing make_request Bearer token
    api_key = @auth_service.api_key
    return { error: 'Authentication failed' } unless api_key

    headers = {
      'x-api-key' => api_key,
      'Content-Type' => 'application/json'
    }

    response = HTTParty.post(endpoint, headers: headers, body: body.to_json)

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "OmiCall API Error: #{response.body}"
      { error: response.parsed_response }
    end
  rescue StandardError => e
    Rails.logger.error "OmiCall API Exception: #{e.message}"
    { error: e.message }
  end

  def register_webhook
    endpoint = "#{API_BASE_URL}/api/webhooks/register"
    body = {
      webhook: {
        type: 'call',
        url: webhook_url,
        events: %w[ringing answered hangup]
      }
    }

    make_request(:post, endpoint, body: body.to_json)
  end

  def unregister_webhook
    endpoint = "#{API_BASE_URL}/api/webhooks/destroy"
    query = { hook_type: 'call' }

    make_request(:post, endpoint, query: query)
  end

  private

  def make_request(method, url, body: nil, query: nil)
    token = @auth_service.access_token
    return { error: 'Authentication failed' } unless token

    headers = {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }

    options = { headers: headers }
    options[:body] = body if body.present?
    options[:query] = query if query.present?

    response = HTTParty.send(method, url, **options)

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "OmiCall API Error: #{response.body}"
      { error: response.parsed_response }
    end
  rescue StandardError => e
    Rails.logger.error "OmiCall API Exception: #{e.message}"
    { error: e.message }
  end

  def webhook_url
    # Fallback host if FRONTEND_URL is not set
    host = ENV.fetch('FRONTEND_URL', 'https://api.shopiz.vn')
    "#{host}/api/v1/webhooks/omicall"
  end
end
