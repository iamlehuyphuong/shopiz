module SuperAdmin::AccountFeaturesHelper
  FEATURE_CATEGORIES = {
    'Kênh kết nối (Channels)' => %w[
      inbound_emails channel_email channel_facebook channel_twitter channel_website
      channel_instagram channel_voice channel_zalo channel_zalopersonal channel_telegram
      channel_api channel_line channel_whatsapp channel_tiktok_shop channel_tiktok
    ],
    'Quản lý & CRM (Management & CRM)' => %w[
      agent_management team_management inbox_management crm crm_v2 companies labels
      custom_attributes custom_roles sales assignment_v2 inbox_view
    ],
    'Năng suất & Tự động hóa (Productivity & Automation)' => %w[
      macros automations canned_responses response_bot auto_resolve_conversations
      workflow survey template_builder conversation_required_attributes advanced_assignment
      campaigns agent_bots voice_recorder
    ],
    'Báo cáo & Phân tích (Reporting & Analytics)' => %w[
      reports report_v4 report_rollup audit_logs csat_review_notes sla
    ],
    'Tích hợp (Integrations)' => %w[
      integrations linear_integration shopify_integration notion_integration crm_integration
    ],
    'AI & ShopizAI (AI & Captain)' => %w[
      captain_integration captain_integration_v2 captain_tasks
    ],
    'Hệ thống & Giao diện (System & Interface)' => %w[
      ip_lookup disable_branding email_continuity_on_api_channel help_center
      help_center_embedding_search chatwoot_v4 search_with_gin
      advanced_search advanced_search_indexing saml reply_mailer_migration quoted_email_reply
      custom_reply_domain custom_reply_email message_reply_to insert_article_in_reply
    ],
    'Khác (Others)' => %w[
      whatsapp_embedded_signup whatsapp_campaign twilio_content_templates
      contact_chatwoot_support_team deprecated_feature_64
    ]
  }.freeze

  def self.account_features
    YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
  end

  def self.account_premium_features
    account_features.filter { |feature| feature['premium'] }.pluck('name')
  end

  # Returns a hash mapping feature names to their display names
  def self.feature_display_names
    account_features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = feature['display_name']
    end
  end

  def self.filter_internal_features(features)
    return features if ChatwootApp.chatwoot_cloud?

    internal_features = account_features.select { |f| f['chatwoot_internal'] }.pluck('name')
    features.except(*internal_features)
  end

  def self.filter_deprecated_features(features)
    deprecated_features = account_features.select { |f| f['deprecated'] }.pluck('name')
    features.except(*deprecated_features)
  end

  def self.sort_and_transform_features(features, display_names)
    features.sort_by { |key, _| display_names[key] || key }
            .to_h
            .transform_keys { |key| [key, display_names[key]] }
  end

  def self.partition_features(features)
    filtered = filter_internal_features(features)
    filtered = filter_deprecated_features(filtered)
    display_names = feature_display_names

    regular, premium = filtered.partition { |key, _value| account_premium_features.exclude?(key) }

    [
      sort_and_transform_features(regular, display_names),
      sort_and_transform_features(premium, display_names)
    ]
  end

  def self.filtered_features(features)
    regular, premium = partition_features(features)
    regular.merge(premium)
  end

  def self.categorized_features(attributes)
    # attributes is an array of Administrate::Field::Base objects
    categorized = {}

    # Initialize categories in order
    FEATURE_CATEGORIES.each_key { |category| categorized[category] = [] }
    categorized['Chưa phân loại (Uncategorized)'] = []

    attributes.each do |attr|
      # attr.data should be a hash with one key (the feature name)
      # based on existing show.html.erb logic: attr.data.keys.first
      feature_name = attr.data.keys.first.to_s rescue nil
      next unless feature_name

      category_found = false
      FEATURE_CATEGORIES.each do |category, features|
        if features.include?(feature_name)
          categorized[category] << attr
          category_found = true
          break
        end
      end

      categorized['Chưa phân loại (Uncategorized)'] << attr unless category_found
    end

    categorized.reject { |_, v| v.empty? }
  end

  def self.categorized_features_hash(features_hash)
    categorized = {}
    FEATURE_CATEGORIES.each_key { |category| categorized[category] = [] }
    categorized['Chưa phân loại (Uncategorized)'] = []

    features_hash.each do |feature_name, enabled|
      category_found = false
      FEATURE_CATEGORIES.each do |category, features|
        if features.include?(feature_name.to_s)
          categorized[category] << [feature_name.to_s, enabled]
          category_found = true
          break
        end
      end

      categorized['Chưa phân loại (Uncategorized)'] << [feature_name.to_s, enabled] unless category_found
    end

    categorized.reject { |_, v| v.empty? }
  end
end
