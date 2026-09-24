module Featurable
  extend ActiveSupport::Concern

  QUERY_MODE = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  DEFAULT_PLAN_FEATURES = %w[
    canned_responses
    crm
    channel_facebook
    inbox_view
    inbox_management
    labels
    macros
    reports
    report_v4
    channel_website
  ].freeze

  DISABLED_FEATURES = %w[
    template_builder
    integrations
    channel_whatsapp
    channel_api
    channel_telegram
    channel_instagram
  ].freeze

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

  def feature_names
    enabled_features.keys
  end

  def feature_names=(names)
    # Ensure names is an array of strings
    names = Array(names).map(&:to_s)

    FEATURE_LIST.each do |feature|
      feature_name = feature['name']
      is_enabled = names.include?(feature_name)
      send("feature_#{feature_name}=", is_enabled)
    end
  end

  def enable_default_features
    enable_features(*DEFAULT_PLAN_FEATURES)
  end
end
