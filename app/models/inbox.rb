# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                            :integer          not null, primary key
#  allow_messages_after_resolved :boolean          default(TRUE)
#  auto_assignment_config        :jsonb
#  business_name                 :string
#  channel_type                  :string
#  csat_config                   :jsonb            not null
#  csat_survey_enabled           :boolean          default(FALSE)
#  email_address                 :string
#  enable_auto_assignment        :boolean          default(TRUE)
#  greeting_enabled              :boolean          default(FALSE)
#  greeting_message              :string
#  is_load_all_conversation      :boolean
#  lock_to_single_conversation   :boolean          default(FALSE), not null
#  name                          :string           not null
#  next_cursor                   :string
#  out_of_office_message         :string
#  sender_name_type              :integer          default("friendly"), not null
#  timezone                      :string           default("UTC")
#  working_hours_enabled         :boolean          default(FALSE)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :integer          not null
#  channel_id                    :integer          not null
#
# Indexes
#
#  index_inboxes_on_account_id                   (account_id)
#  index_inboxes_on_channel_id_and_channel_type  (channel_id,channel_type)
#

class Inbox < ApplicationRecord
  include Reportable
  include Avatarable
  include OutOfOffisable
  include AccountCacheRevalidator
  include InboxAgentAvailability

  ENABLE_LOAD_HISTORY_CONVERSATION = ['Channel::FacebookPage', 'Channel::Instagram', 'Channel::ZaloOa', 'Channel::TiktokShop'].freeze

  LOAD_HISTORY_CONVERSATION_SERVICES = {
    'Channel::FacebookPage' => 'Facebook::LoadHistoryConversationService',
    'Channel::Instagram' => 'Instagram::LoadHistoryConversationService',
    'Channel::ZaloOa' => 'Zalo::LoadHistoryConversationService',
    'Channel::TiktokShop' => 'TiktokShop::LoadHistoryConversationService'
  }.freeze

  # Integration app_ids considered as e-commerce platforms
  ECOMMERCE_APP_IDS = %w[kiotviet sapo haravan shopify woocommerce nhanhvn tiktok_shop].freeze

  # Channel types that are permanently linked to their native e-commerce platform
  MARKETPLACE_CHANNEL_MAP = {
    'Channel::TiktokShop' => 'tiktok_shop'
    # 'Channel::Lazada' => 'lazada',
    # 'Channel::Shopee' => 'shopee',
  }.freeze

  # Not allowing characters:
  validates :name, presence: true
  validates :account_id, presence: true
  validates :timezone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  validates :out_of_office_message, length: { maximum: Limits::OUT_OF_OFFICE_MESSAGE_MAX_LENGTH }
  validates :greeting_message, length: { maximum: Limits::GREETING_MESSAGE_MAX_LENGTH }
  validate :ensure_valid_max_assignment_limit
  validate :validate_auto_follow_up_config

  store_accessor :zalo_auto_message_config, :zalo_auto_message_enabled, :zalo_auto_message_inbox_ids

  belongs_to :account
  belongs_to :ecommerce_integration, class_name: 'Integrations::Hook', optional: true

  belongs_to :channel, polymorphic: true, dependent: :destroy

  has_many :campaigns, dependent: :destroy_async
  has_many :contact_inboxes, dependent: :destroy_async
  has_many :contacts, through: :contact_inboxes
  has_many :contact_optins, dependent: :destroy_async

  has_many :inbox_members, dependent: :destroy_async
  has_many :members, through: :inbox_members, source: :user
  has_many :conversations, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async

  has_one :inbox_assignment_policy, dependent: :destroy
  has_one :assignment_policy, through: :inbox_assignment_policy
  has_one :agent_bot_inbox, dependent: :destroy_async
  has_one :agent_bot, through: :agent_bot_inbox
  has_many :inbox_label_mappings, dependent: :destroy_async
  has_many :webhooks, dependent: :destroy_async
  has_many :hooks, dependent: :destroy_async, class_name: 'Integrations::Hook'

  enum sender_name_type: { friendly: 0, professional: 1 }

  after_destroy :delete_round_robin_agents

  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event
  after_create_commit :auto_load_old_conversation

  scope :order_by_name, -> { order('lower(name) ASC') }

  # Adds multiple members to the inbox
  # @param user_ids [Array<Integer>] Array of user IDs to add as members
  # @return [void]
  def add_members(user_ids)
    inbox_members.create!(user_ids.map { |user_id| { user_id: user_id } })
    update_account_cache
  end

  # Removes multiple members from the inbox
  # @param user_ids [Array<Integer>] Array of user IDs to remove
  # @return [void]
  def remove_members(user_ids)
    inbox_members.where(user_id: user_ids).destroy_all
    update_account_cache
  end

  # Sanitizes inbox name for balanced provider compatibility
  # ALLOWS: /'._- and Unicode letters/numbers/emojis
  # REMOVES: Forbidden chars (\<>@") + spam-trigger symbols (!#$%&*+=?^`{|}~)
  def sanitized_name
    return '' if name.blank?

    apply_sanitization_rules(name)
  end

  def facebook?
    channel_type == 'Channel::FacebookPage'
  end

  def instagram?
    (facebook? || instagram_direct?) && channel.instagram_id.present?
  end

  def instagram_direct?
    channel_type == 'Channel::Instagram'
  end

  def tiktok?
    channel_type == 'Channel::Tiktok'
  end

  def web_widget?
    channel_type == 'Channel::WebWidget'
  end

  def api?
    channel_type == 'Channel::Api'
  end

  def telegram?
    channel_type == 'Channel::Telegram'
  end

  def whatsapp?
    channel_type == 'Channel::Whatsapp'
  end

  def zalo_personal?
    channel_type == 'Channel::ZaloPersonal'
  end

  def zalo_oa?
    channel_type == 'Channel::ZaloOa'
  end

  def assignable_agents
    (account.users.where(id: members.select(:user_id)) + account.administrators).uniq
  end

  def active_bot?
    agent_bot_inbox&.active? || hooks.any? { |hook| hook.app_id.in?(%w[dialogflow]) && hook.enabled? }
  end

  def marketplace_channel?
    MARKETPLACE_CHANNEL_MAP.key?(channel_type)
  end

  def auto_linked_platform
    MARKETPLACE_CHANNEL_MAP[channel_type]
  end

  # Returns the effective e-commerce hook for this inbox.
  # Marketplace channels (TikTok Shop) are auto-linked to their native platform hook.
  # Generic channels use the explicitly assigned ecommerce_integration.
  def effective_ecommerce_hook
    if marketplace_channel?
      account.hooks.find_by(app_id: auto_linked_platform)
    else
      ecommerce_integration
    end
  end

  def inbox_type
    channel.name
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def callback_webhook_url
    case channel_type

    when 'Channel::Whatsapp'
      "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{channel.phone_number}"
    end
  end

  def member_ids_with_assignment_capacity
    members.ids
  end

  def advanced_assignment_enabled?
    account.feature_enabled?('advanced_assignment')
  end

  private

  def apply_sanitization_rules(name)
    name.gsub(/[\\<>@"!#$%&*+=?^`{|}~:;]/, '')         # Remove forbidden chars
        .gsub(/[\x00-\x1F\x7F]/, ' ')                   # Replace control chars with spaces
        .gsub(/\A[[:punct:]]+|[[:punct:]]+\z/, '')      # Remove leading/trailing punctuation
        .gsub(/\s+/, ' ')                               # Normalize spaces
        .strip
  end

  def dispatch_create_event
    return if ENV['ENABLE_INBOX_EVENTS'].blank?

    Rails.configuration.dispatcher.dispatch(INBOX_CREATED, Time.zone.now, inbox: self)
  end

  def dispatch_update_event
    return if ENV['ENABLE_INBOX_EVENTS'].blank?

    Rails.configuration.dispatcher.dispatch(INBOX_UPDATED, Time.zone.now, inbox: self, changed_attributes: previous_changes)
  end

  def ensure_valid_max_assignment_limit
    # overridden in enterprise/app/models/enterprise/inbox.rb
  end

  def validate_auto_follow_up_config
    return if auto_follow_up_config.blank?

    max = auto_follow_up_config['max_attempts'].to_i
    errors.add(:auto_follow_up_config, 'max_attempts cannot exceed 15') if max > 15
  end

  def delete_round_robin_agents
    ::AutoAssignment::InboxRoundRobinService.new(inbox: self).clear_queue
  end

  def auto_load_old_conversation
    return if ENABLE_LOAD_HISTORY_CONVERSATION.exclude?(channel.class.to_s)

    service_class_name = LOAD_HISTORY_CONVERSATION_SERVICES[channel.class.to_s]
    return if service_class_name.blank?

    service_class_name.constantize.new(self).perform
  end
end

Inbox.prepend_mod_with('Inbox')
Inbox.include_mod_with('Audit::Inbox')
Inbox.include_mod_with('Concerns::Inbox')
