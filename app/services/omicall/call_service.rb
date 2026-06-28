class Omicall::CallService
  API_BASE_URL = 'https://api.omicall.com/omicall-api'.freeze

  def initialize(account)
    @account = account
    @auth_service = Omicall::AuthService.new(account)
  end

  def click2call(extension:, hotline:, phone_number:)
    endpoint = "#{API_BASE_URL}/click2call"
    body = {
      extension: extension,
      hotline: hotline,
      phone_number: phone_number
    }

    make_request(:post, endpoint, body: body.to_json)
  end

  def internal_phones(page: 1, size: 100)
    endpoint = "#{API_BASE_URL}/call_center/internal_phone/list"
    query = { page: page, size: size }
    make_request(:get, endpoint, query: query)
  end

  def request_callbot(contacts:, sip_numbers:, script_id:, session_name:, voice: 'northern_female_ngocanh')
    endpoint = "#{API_BASE_URL}/v2/call-bot/request"
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
