# == Schema Information
#
# Table name: integrations_hooks
#
#  id           :bigint           not null, primary key
#  access_token :string
#  hook_type    :integer          default("account")
#  settings     :jsonb
#  status       :integer          default("enabled")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  app_id       :string
#  inbox_id     :integer
#  reference_id :string
#
class Integrations::Hook < ApplicationRecord
  include Reauthorizable

  attr_readonly :app_id, :account_id, :inbox_id, :hook_type
  before_validation :ensure_hook_type
  before_validation :move_secrets_to_encrypted_settings
  after_create :trigger_setup_if_crm
  after_create :trigger_setup_if_calendly
  after_create_commit :trigger_setup_if_omicall
  before_destroy :trigger_teardown_if_omicall

  SECRET_KEYS = %w[
    api_key
    credentials
    access_token
    consumer_key
    consumer_secret
    access_key
    secret_key
  ].freeze

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  encrypts :access_token, deterministic: true if Chatwoot.encryption_configured?

  serialize :encrypted_settings, coder: JSON
  encrypts :encrypted_settings if Chatwoot.encryption_configured?

  validates :account_id, presence: true
  validates :app_id, presence: true
  validates :inbox_id, presence: true, if: -> { hook_type == 'inbox' }
  validate :validate_settings_json_schema
  validate :ensure_feature_enabled
  validate :validate_openai_api_key, if: -> { app_id == 'openai' && settings.present? }
  validates :app_id, uniqueness: { scope: [:account_id], unless: -> { app.present? && app.params[:allow_multiple_hooks].present? } }

  # TODO: This seems to be only used for slack at the moment
  # We can add a validator when storing the integration settings and toggle this in future
  enum status: { disabled: 0, enabled: 1 }

  belongs_to :account
  belongs_to :inbox, optional: true
  has_secure_token :access_token

  enum hook_type: { account: 0, inbox: 1 }

  scope :account_hooks, -> { where(hook_type: 'account') }
  scope :inbox_hooks, -> { where(hook_type: 'inbox') }

  def app
    @app ||= Integrations::App.find(id: app_id)
  end

  def slack?
    app_id == 'slack'
  end

  def dialogflow?
    app_id == 'dialogflow'
  end

  def notion?
    app_id == 'notion'
  end

  def disable
    update(status: 'disabled')
  end

  def process_event(_event)
    # OpenAI integration migrated to Captain::EditorService
    # Other integrations (slack, dialogflow, etc.) handled via HookJob
    { error: 'No processor found' }
  end

  def hook_api_key
    merged_settings['api_key']
  end

  def merged_settings
    enc_settings = begin
      encrypted_settings.dup
    rescue StandardError
      encrypted_settings
    end
    if enc_settings.is_a?(String)
      begin
        enc_settings = JSON.parse(enc_settings)
      rescue JSON::ParserError
        enc_settings = {}
      end
    end

    if enc_settings.is_a?(Hash)
      # If p and h are present (due to previous nested encryption bug), remove them
      has_p_and_h = enc_settings.key?('p') && enc_settings.key?('h')
      enc_settings.delete('p')
      enc_settings.delete('h')

      # If we had p and h (meaning it was a raw payload or nested), and secret keys are missing, provide [FILTERED]
      if has_p_and_h
        schema_keys = app&.params&.dig(:settings_json_schema, :properties)&.keys || []
        (SECRET_KEYS & schema_keys.map(&:to_s)).each do |k|
          enc_settings[k] = '[FILTERED]' unless enc_settings.key?(k)
        end
      end
    end

    (settings || {}).merge(enc_settings || {})
  end

  def feature_allowed?
    return true if app.blank?

    flag = app.params[:feature_flag]
    return true unless flag

    account.feature_enabled?(flag)
  end

  private

  def move_secrets_to_encrypted_settings
    return unless settings.is_a?(Hash)

    if encrypted_settings.is_a?(String)
      begin
        self.encrypted_settings = JSON.parse(encrypted_settings)
      rescue JSON::ParserError
        self.encrypted_settings = {}
      end
    end

    self.encrypted_settings ||= {}
    SECRET_KEYS.each do |key|
      if settings.key?(key)
        val = settings.delete(key)
        self.encrypted_settings[key] = val unless val == '[FILTERED]'
      end
    end
  end

  def ensure_feature_enabled
    errors.add(:feature_flag, 'Feature not enabled') unless feature_allowed?
  end

  def ensure_hook_type
    self.hook_type = app.params[:hook_type] if app.present?
  end

  def validate_settings_json_schema
    return if app.blank? || app.params[:settings_json_schema].blank?

    return if JSONSchemer.schema(app.params[:settings_json_schema]).valid?(merged_settings.with_indifferent_access)

    errors.add(:settings,
               ': Invalid settings data')
  end

  def validate_openai_api_key
    # Ensure RubyLLM requires are loaded
    require 'ruby_llm'
    Llm::Config.initialize!

    api_key = hook_api_key
    return if api_key.blank? || api_key == '[FILTERED]'

    api_base = settings['api_base_url']
    base_url = (api_base.chomp('/').sub(%r{/v1\z}, '') if api_base.present? && !api_base.chomp('/').match?(%r{\Ahttps://api\.openai\.com(/v1)?\z}))

    Llm::Config.with_api_key(api_key, api_base: base_url) do |context|
      # We send a tiny request to verify the key
      context.chat(model: settings['model'].presence || 'gpt-4o-mini').ask('ping')
    end
  rescue StandardError => e
    # Add error if authentication fails or endpoint is unreachable
    errors.add(:settings, "API Key validation failed: #{e.message}")
  end

  def trigger_setup_if_crm
    # we need setup services to create data prerequisite to functioning of the integration
    # in case of Leadsquared, we need to create a custom activity type for capturing conversations and transcripts
    # https://apidocs.leadsquared.com/create-new-activity-type-api/
    return unless crm_integration?

    ::Crm::SetupJob.perform_later(id)
  end

  def crm_integration?
    %w[leadsquared].include?(app_id)
  end

  def trigger_setup_if_calendly
    return unless app_id == 'calendly'

    ::Calendly::SetupJob.perform_later(id)
  end

  def trigger_setup_if_omicall
    return unless app_id == 'omicall'

    ::Omicall::SetupWebhookJob.perform_later(id)
  end

  def trigger_teardown_if_omicall
    return unless app_id == 'omicall'

    api_key = hook_api_key

    ::Omicall::TeardownWebhookJob.perform_later(account_id, api_key)
  end
end
