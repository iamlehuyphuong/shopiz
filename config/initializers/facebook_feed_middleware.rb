# frozen_string_literal: true

# Insert the Facebook Feed webhook middleware before the Facebook Messenger gem's server.
# This middleware intercepts POST requests to /bot, extracts feed change events (e.g., comments),
# and dispatches them to a background job. The rest of the request continues to the gem.
require 'facebook/feed_webhook_middleware'

Rails.application.config.middleware.insert_before(0, Facebook::FeedWebhookMiddleware)
