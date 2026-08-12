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
    # For Instagram Business Login, webhook subscriptions are managed entirely
    # via the Meta App Dashboard (Instagram Webhooks product) and the OAuth permission grant.
    # There is no API edge to "install" the app like Facebook Pages (/{page-id}/subscribed_apps).
    # Therefore, this is a no-op.
    true
  end

  def unsubscribe
    # No-op for the same reason as subscribe.
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
