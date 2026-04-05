module Featurable
  extend ActiveSupport::Concern

  QUERY_MODE = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  DEFAULT_PLAN_FEATURES = %w[
    canned_responses
    crm
    crm_v2
    channel_facebook
    inbox_view
    inbox_management
    labels
    macros
    reports
    report_v4
    chatwoot_v4
    channel_website
  ].freeze

  DISABLED_FEATURES = %w[
    help_center
    template_builder
    integrations
    channel_whatsapp
    channel_email
    channel_api
    channel_telegram
    channel_line
    channel_instagram
    channel_voice
  ].freeze

  MAPPING = {
    ie: :inbound_emails,
    che: :channel_email,
    chf: :channel_facebook,
    chtt: :channel_twitter,
    il: :ip_lookup,
    db: :disable_branding,
    ecac: :email_continuity_on_api_channel,
    hc: :help_center,
    ab: :agent_bots,
    agm: :agent_management,
    mc: :macros,
    tm: :team_management,
    im: :inbox_management,
    lb: :labels,
    ca: :custom_attributes,
    atm: :automations,
    cr: :canned_responses,
    ig: :integrations,
    vr: :voice_recorder,
    m2: :mobile_v2,
    chw: :channel_website,
    cp: :campaigns,
    s: :sales,
    rp: :reports,
    crm: :crm,
    arc: :auto_resolve_conversations,
    cre: :custom_reply_email,
    crd: :custom_reply_domain,
    al: :audit_logs,
    rb: :response_bot,
    mr: :message_reply_to,
    iair: :insert_article_in_reply,
    iv: :inbox_view,
    sla: :sla,
    hces: :help_center_embedding_search,
    li: :linear_integration,
    ci: :captain_integration,
    cro: :custom_roles,
    cw4: :chatwoot_v4,
    r4: :report_v4,
    ccst: :contact_chatwoot_support_team,
    si: :shopify_integration,
    swg: :search_with_gin,
    chi: :channel_instagram,
    crmi: :crm_integration,
    ni: :notion_integration,
    ci2: :captain_integration_v2,
    waes: :whatsapp_embedded_signup,
    wac: :whatsapp_campaign,
    crm2: :crm_v2,
    as2: :assignment_v2,
    tct: :twilio_content_templates,
    as: :advanced_search,
    saml: :saml,
    tb: :template_builder,
    asi: :advanced_search_indexing,
    rmm: :reply_mailer_migration,
    qer: :quoted_email_reply,
    chz: :channel_zalo,
    chzp: :channel_zalopersonal,
    cht: :channel_telegram,
    cha: :channel_api,
    chv: :channel_voice,
    chl: :channel_line,
    whwa: :channel_whatsapp,
    wf: :workflow,
    sv: :survey,
    chtk: :channel_tiktok
  }.freeze

  FEATURE_LIST = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze

  FEATURES = FEATURE_LIST.each_with_object({}) do |feature, result|
    result[result.keys.size + 1] = "feature_#{feature['name']}".to_sym
  end

  included do
    include FlagShihTzu
    # We split features across two columns since bigint is 64-bit and we have 69 features.
    # We use 63 bits per column to avoid issues with the sign bit in PostgreSQL/ActiveRecord.
    has_flags FEATURES.select { |k, _v| k <= 63 }.merge(column: 'feature_flags').merge(QUERY_MODE)
    has_flags FEATURES.select { |k, _v| k > 63 }.transform_keys { |k| k - 63 }.merge(column: 'feature_flags_2').merge(QUERY_MODE)

    before_create :enable_default_features
    after_create_commit :assign_free_plan
  end

  def enable_features(*names)
    names.each do |name|
      send("feature_#{name}=", true)
    end
  end

  def enable_features!(*names)
    enable_features(*names)
    save
  end

  def disable_features(*names)
    names.each do |name|
      send("feature_#{name}=", false)
    end
  end

  def disable_features!(*names)
    disable_features(*names)
    save
  end

  def feature_enabled?(name)
    send("feature_#{name}?")
  end

  def all_features
    FEATURE_LIST.pluck('name').index_with do |feature_name|
      feature_enabled?(feature_name)
    end
  end

  def enabled_features
    all_features.select { |_feature, enabled| enabled == true }
  end

  def disabled_features
    all_features.select { |_feature, enabled| enabled == false }
  end

  def enable_default_features
    enable_features(*DEFAULT_PLAN_FEATURES)
  end

  def assign_free_plan
    free_plan = Polar::ProductService.by_name('free')
    return unless free_plan

    ::Account::AssignPlanService.new(self, free_plan['id']).execute
  end
end
