# == Schema Information
#
# Table name: channel_facebook_pages
#
#  id                :integer          not null, primary key
#  page_access_token :string           not null
#  user_access_token :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :integer          not null
#  instagram_id      :string
#  page_id           :string           not null
#
# Indexes
#
#  index_channel_facebook_pages_on_page_id                 (page_id)
#  index_channel_facebook_pages_on_page_id_and_account_id  (page_id,account_id) UNIQUE
#

class Channel::FacebookPage < ApplicationRecord
  include Channelable
  include Reauthorizable

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :page_access_token
    encrypts :user_access_token
  end

  self.table_name = 'channel_facebook_pages'
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
                 :auto_reply_ai_prompt      # String  - AI prompt for generating reply

  validates :page_id, uniqueness: { scope: :account_id }

  after_create_commit :subscribe
  before_destroy :unsubscribe

  def name
    'Facebook'
  end

  def create_contact_inbox(instagram_id, name)
    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: { name: name }
                                                          }).perform
  end

  def subscribe
    # ref https://developers.facebook.com/docs/messenger-platform/reference/webhook-events
    Facebook::Messenger::Subscriptions.subscribe(
      access_token: page_access_token,
      subscribed_fields: %w[
        messages message_deliveries message_echoes message_reads messaging_postbacks messaging_referrals messaging_optins feed
      ]
    )
  rescue StandardError => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def unsubscribe
    Facebook::Messenger::Subscriptions.unsubscribe(access_token: page_access_token)
  rescue StandardError => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
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
end
