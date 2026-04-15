# frozen_string_literal: true

# Rack middleware that intercepts Facebook webhook POST requests to the /bot endpoint.
# It extracts 'feed' change events (e.g., comments on posts) and dispatches them
# to a background job, since the facebook-messenger gem only handles 'messaging' events.
class Facebook::FeedWebhookMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if facebook_bot_post?(request)
      body = request.body.read
      request.body.rewind

      payload = JSON.parse(body)
      extract_feed_events(payload)
    end

    @app.call(env)
  rescue JSON::ParserError
    @app.call(env)
  end

  private

  def facebook_bot_post?(request)
    request.post? && request.path == '/bot'
  end

  def extract_feed_events(payload)
    return unless payload['object'] == 'page'

    entries = payload['entry'] || []
    entries.each do |entry|
      page_id = entry['id']
      changes = entry['changes'] || []

      changes.each do |change|
        next unless change['field'] == 'feed'

        value = change['value']
        next unless value
        # Only process new comments (not edits, removes, etc.)
        next unless value['item'] == 'comment' && value['verb'] == 'add'

        Webhooks::FacebookFeedJob.perform_later(page_id, value.to_json)
      end
    end
  end
end
