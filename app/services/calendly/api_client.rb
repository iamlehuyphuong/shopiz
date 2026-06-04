class Calendly::ApiClient
  BASE_URL = 'https://api.calendly.com'.freeze
  TIMEOUT_OPEN = 10
  TIMEOUT_READ = 30

  class ApiError < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  def initialize(access_token)
    @access_token = access_token
  end

  # --- User / Organization ---

  def current_user
    get('/users/me')
  end

  # --- Event Types ---

  def event_types(user_uri:, active: true)
    params = { user: user_uri, active: active }
    get('/event_types', params)
  end

  def event_type(event_type_uuid:)
    get("/event_types/#{event_type_uuid}")
  end

  # --- Available Times ---

  # NOTE: Calendly limits to 7 days per request
  def available_times(event_type_uri:, start_time:, end_time:)
    params = {
      event_type: event_type_uri,
      start_time: start_time.utc.iso8601,
      end_time: end_time.utc.iso8601
    }
    get('/event_type_available_times', params)
  end

  # --- Scheduling (Book appointment) ---

  def create_invitee(event_type_uri:, start_time:, invitee:, location: nil, event_guests: nil, questions_and_answers: nil)
    body = {
      event_type: event_type_uri,
      start_time: start_time,
      invitee: invitee
    }
    body[:location] = location if location.present?
    body[:event_guests] = event_guests if event_guests.present?
    body[:questions_and_answers] = questions_and_answers if questions_and_answers.present?

    post('/invitees', body)
  end

  # --- Scheduled Events ---

  def scheduled_events(user_uri: nil, organization_uri: nil, min_start_time: nil, max_start_time: nil, status: 'active',
                       count: 20)
    params = { status: status, count: count }
    params[:user] = user_uri if user_uri.present?
    params[:organization] = organization_uri if organization_uri.present?
    params[:min_start_time] = min_start_time.utc.iso8601 if min_start_time.present?
    params[:max_start_time] = max_start_time.utc.iso8601 if max_start_time.present?

    get('/scheduled_events', params.compact)
  end

  def event_invitees(event_uuid:)
    get("/scheduled_events/#{event_uuid}/invitees")
  end

  # --- Webhook Subscriptions ---

  def create_webhook_subscription(url:, events:, organization_uri:, scope: 'organization', signing_key: nil)
    body = {
      url: url,
      events: events,
      organization: organization_uri,
      scope: scope
    }
    body[:signing_key] = signing_key if signing_key.present?

    post('/webhook_subscriptions', body)
  end

  def delete_webhook_subscription(webhook_uuid:)
    delete("/webhook_subscriptions/#{webhook_uuid}")
  end

  private

  def get(path, params = {})
    uri = build_uri(path, params)
    request = Net::HTTP::Get.new(uri)
    execute(uri, request)
  end

  def post(path, body = {})
    uri = build_uri(path)
    request = Net::HTTP::Post.new(uri)
    request.body = body.to_json
    request['Content-Type'] = 'application/json'
    execute(uri, request)
  end

  def delete(path)
    uri = build_uri(path)
    request = Net::HTTP::Delete.new(uri)
    execute(uri, request)
  end

  def build_uri(path, params = {})
    uri = URI.parse("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params.compact) if params.present?
    uri
  end

  def execute(uri, request)
    request['Authorization'] = "Bearer #{@access_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT_OPEN
    http.read_timeout = TIMEOUT_READ

    response = http.request(request)

    handle_response(response)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      return {} if response.body.blank?

      JSON.parse(response.body)
    when Net::HTTPBadRequest
      raise ApiError.new('Validation error', status: 400, body: parse_error(response))
    when Net::HTTPUnauthorized
      raise ApiError.new('Unauthorized — invalid or expired token', status: 401, body: parse_error(response))
    when Net::HTTPForbidden
      raise ApiError.new('Forbidden — insufficient permissions', status: 403, body: parse_error(response))
    when Net::HTTPNotFound
      raise ApiError.new('Resource not found', status: 404, body: parse_error(response))
    else
      raise ApiError.new("Calendly API error (#{response.code})", status: response.code.to_i, body: parse_error(response))
    end
  end

  def parse_error(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    { 'message' => response.body }
  end
end
