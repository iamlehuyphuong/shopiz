# frozen_string_literal: true

# Override the hardcoded Graph API version (v3.2) in the facebook-messenger gem
# to use the latest version (v25.0) for all Messenger Platform API calls.
#
# The gem hardcodes `base_uri 'https://graph.facebook.com/v3.2/me'` in:
#   - Facebook::Messenger::Bot
#   - Facebook::Messenger::Subscriptions
#   - Facebook::Messenger::Profile
#
# This monkey-patch updates all three to use v25.0.

Rails.application.config.to_prepare do
  Facebook::Messenger::Bot.base_uri 'https://graph.facebook.com/v25.0/me'
  Facebook::Messenger::Subscriptions.base_uri 'https://graph.facebook.com/v25.0/me'
  Facebook::Messenger::Profile.base_uri 'https://graph.facebook.com/v25.0/me'
end
