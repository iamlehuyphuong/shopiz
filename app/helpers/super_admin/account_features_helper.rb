module SuperAdmin::AccountFeaturesHelper
  FEATURE_CATEGORIES = {
    'Kênh kết nối (Channels)' => %w[
      channel_facebook channel_website
      channel_instagram channel_zalo channel_zalopersonal channel_telegram
      channel_whatsapp channel_tiktok_shop channel_tiktok
    ],
    'Quản lý & CRM (Management & CRM)' => %w[
      agent_management team_management inbox_management crm companies labels
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
      captain_integration captain_tasks
    ],
    'Hệ thống & Giao diện (System & Interface)' => %w[
      ip_lookup disable_branding
      search_with_gin
      advanced_search advanced_search_indexing message_reply_to
    ],
    'Khác (Others)' => %w[
      whatsapp_embedded_signup whatsapp_campaign
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
    features.sort_by { |key, enabled| [enabled ? 0 : 1, display_names[key] || key] }
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

    deprecated_features = account_features.select { |f| f['deprecated'] }.pluck('name')

    attributes.each do |attr|
      # attr.data should be a hash with one key (the feature name)
      # based on existing show.html.erb logic: attr.data.keys.first
      feature_name = begin
        attr.data.keys.first.to_s
      rescue StandardError
        nil
      end
      next unless feature_name
      next if deprecated_features.include?(feature_name)

      category_found = false
      FEATURE_CATEGORIES.each do |category, features|
        next unless features.include?(feature_name)

        categorized[category] << attr
        category_found = true
        break
      end

      categorized['Chưa phân loại (Uncategorized)'] << attr unless category_found
    end

    # Sort features within each category: enabled (data value is true) first, then by display name
    display_names = feature_display_names
    categorized.each do |category, category_attributes|
      categorized[category] = category_attributes.sort_by do |attr|
        feature_name = attr.data.keys.first.to_s
        is_enabled = attr.data.values.first
        display_name = display_names[feature_name] || feature_name
        [is_enabled ? 0 : 1, display_name]
      end
    end

    categorized.reject { |_, v| v.empty? }
  end

  def self.categorized_features_hash(features_hash)
    categorized = {}
    FEATURE_CATEGORIES.each_key { |category| categorized[category] = [] }
    categorized['Chưa phân loại (Uncategorized)'] = []

    deprecated_features = account_features.select { |f| f['deprecated'] }.pluck('name')

    features_hash.each do |feature_name, enabled|
      next if deprecated_features.include?(feature_name.to_s)

      category_found = false
      FEATURE_CATEGORIES.each do |category, features|
        next unless features.include?(feature_name.to_s)

        categorized[category] << [feature_name.to_s, enabled]
        category_found = true
        break
      end

      categorized['Chưa phân loại (Uncategorized)'] << [feature_name.to_s, enabled] unless category_found
    end

    # Sort features within each category: enabled first, then by display name
    display_names = feature_display_names
    categorized.each do |category, features|
      categorized[category] = features.sort_by do |feature_name, enabled|
        display_name = display_names[feature_name] || feature_name
        [enabled ? 0 : 1, display_name]
      end
    end

    categorized.reject { |_, v| v.empty? }
  end
end
