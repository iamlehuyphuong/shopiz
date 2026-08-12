# == Schema Information
#
# Table name: channel_instagram
#
#  id           :bigint           not null, primary key
#  access_token :string           not null
#  expires_at   :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  instagram_id :string           not null
#
# Indexes
#
#  index_channel_instagram_on_instagram_id  (instagram_id) UNIQUE
#
class Channel::Instagram < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_instagram'

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  encrypts :access_token if Chatwoot.encryption_configured?

  EDITABLE_ATTRS = [{ provider_config: {} }].freeze

  # Post & comment management settings stored in provider_config JSONB column
  store_accessor :provider_config,
                 :hide_comments,            # Boolean - hide all comments
                 :hide_phone_comments,      # Boolean - hide comments containing phone number
                 :hide_email_comments,      # Boolean - hide comments containing email
                 :auto_reply_to_comments,   # Boolean - send private reply to commenters
                 :auto_reply_use_ai,        # Boolean - use AI to generate reply
                 :auto_reply_message,       # String  - message content for private reply
                 :auto_public_reply_to_comments, # Boolean - send public reply to commenters
                 :auto_public_reply_message,     # String  - message content for public reply
                 :auto_reply_ai_prompt,     # String  - AI prompt for generating reply
                 :page_id                   # String  - linked Facebook Page ID (required for Private Replies API)

  AUTHORIZATION_ERROR_THRESHOLD = 1

  validates :access_token, presence: true
  validates :instagram_id, uniqueness: true, presence: true

  after_create_commit :subscribe
  before_destroy :unsubscribe

  def name
    'Instagram'
  end

  def create_contact_inbox(instagram_id, name, avatar_url: nil)
    attrs = { name: name }
    attrs[:avatar_url] = avatar_url if avatar_url.present?

    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: attrs
                                                          }).perform
  end

  def subscribe
    # Instagram Business Login requires subscribing the app to the IG user's webhooks.
    # App Dashboard configures WHAT events at WHICH URL (app-level).
    # This API call tells Meta THIS specific IG account opts in to send events to our app (user-level).
    # ref: https://developers.facebook.com/docs/instagram-platform/webhooks#enable-subscriptions
    api_version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
    response = HTTParty.post(
      "https://graph.instagram.com/#{api_version}/#{instagram_id}/subscribed_apps",
      query: {
        subscribed_fields: 'messages,messaging_seen,message_reactions,comments',
        access_token: access_token
      }
    )

    if response.success?
      Rails.logger.info "[Instagram] Successfully subscribed webhooks for IG user #{instagram_id}: #{response.body}"
    else
      Rails.logger.error "[Instagram] Failed to subscribe webhooks for IG user #{instagram_id}. " \
                         "Status: #{response.code}, Body: #{response.body}"
    end
    true
  rescue StandardError => e
    Rails.logger.error "[Instagram] Exception subscribing webhooks for #{instagram_id}: #{e.message}"
    true
  end

  def unsubscribe
    api_version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
    HTTParty.delete(
      "https://graph.instagram.com/#{api_version}/#{instagram_id}/subscribed_apps",
      query: { access_token: access_token }
    )
    Rails.logger.info "[Instagram] Unsubscribed webhooks for IG user #{instagram_id}"
    true
  rescue StandardError => e
    Rails.logger.error "[Instagram] Exception unsubscribing webhooks for #{instagram_id}: #{e.message}"
    true
  end

  def access_token
    Instagram::RefreshOauthTokenService.new(channel: self).access_token
  end

  # Helper methods for checking boolean provider_config values
  def hide_comments?
    ActiveModel::Type::Boolean.new.cast(hide_comments)
  end

  def hide_phone_comments?
    ActiveModel::Type::Boolean.new.cast(hide_phone_comments)
  end

  def hide_email_comments?
    ActiveModel::Type::Boolean.new.cast(hide_email_comments)
  end

  def auto_reply_to_comments?
    ActiveModel::Type::Boolean.new.cast(auto_reply_to_comments)
  end

  def auto_public_reply_to_comments?
    ActiveModel::Type::Boolean.new.cast(auto_public_reply_to_comments)
  end

  def auto_reply_use_ai?
    ActiveModel::Type::Boolean.new.cast(auto_reply_use_ai)
  end
end
