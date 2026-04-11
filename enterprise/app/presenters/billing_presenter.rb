class BillingPresenter
  PRODUCT_TYPES = %w[starter pro biz ai-start ai-pro ai-biz].freeze
  MONTH_OPTIONS = %w[6 12].freeze

  def initialize(account)
    @account = account
  end

  def json_data
    {
      usage: usage_data,
      plans: plans_data,
      trial_plan: trial_data,
      enterprise_plan: enterprise_data,
      credits: credit_data,
      billing_histories: billing_histories_data,
      disabled_register_trial: disabled_register_trial,
      current_subscription: current_subscription,
      current_addons: current_addons,
      all_addon_packages: all_addon_packages
    }
  end

  private

  def custom_attributes
    @custom_attributes ||= @account.custom_attributes
  end
  
  def current_subscription
    sub = @account.active_subscription
    
    if sub
      rank = PRODUCT_TYPES.index((sub.subscription_plan.name_en || '').downcase) || -1
      return {
        plan_id: sub.subscription_plan_id,
        plan_name: sub.subscription_plan.name(@account.locale),
        ends_at: sub.ends_at,
        starts_at: sub.starts_at,
        is_free: sub.subscription_plan.is_free,
        rank: rank,
        price: {
          price_amount: sub.subscription_plan.price_amount.to_f,
          currency: sub.subscription_plan.currency
        }
      }
    end

    sku = @account.custom_attributes['sku']
    plan = SubscriptionPlan.find_by(sku: sku) if sku.present?
    
    return nil unless plan
    
    rank = PRODUCT_TYPES.index((plan.name_en || '').downcase) || -1
    {
      plan_id: plan.id,
      plan_name: plan.name(@account.locale),
      ends_at: @account.custom_attributes['subscription_ends_on'],
      starts_at: nil,
      is_free: plan.is_free,
      rank: rank,
      price: {
        price_amount: plan.price_amount.to_f,
        currency: plan.currency
      }
    }
  end

  def current_addons
    @account.account_addons.active.includes(:addon_package).map do |addon|
      {
        id: addon.id,
        addon_package_id: addon.addon_package_id,
        name: addon.addon_package.name,
        quantity: addon.quantity,
        addon_type: addon.addon_type
      }
    end
  end

  def usage_data
    {
      agents: usage_agent,
      inboxes: usage_inbox,
      contacts: usage_contact,
      automations: usage_automation,
      captain_documents: usage_captain_document,
      captain_faqs: usage_captain_faq,
      captain_assistants: usage_captain_assistant,
      captain_responses: usage_captain_responses,
      captain_responses_credit: usage_captain_responses_credit
    }
  end

  def plans_data
    all_plans = SubscriptionPlan.joins(:subscription_tier)
                                .where(visible: true, subscription_tiers: { is_free: false })
                                .includes(:subscription_tier).to_a

    tiers = all_plans.group_by { |p| p.subscription_tier_id }
    
    formatted_tiers = tiers.map do |_tier_id, tier_plans|
      sorted_plans = tier_plans.sort_by { |p| [p.duration_days.to_i, p.ai_included? ? 1 : 0] }
      base_plan = sorted_plans.find { |p| p.duration_days == 180 && !p.ai_included? } || sorted_plans.first
      tier = base_plan&.subscription_tier

      tier_key = (tier&.name_en || 'other').downcase
      
      base_price_monthly = 0.0
      if base_plan && base_plan.duration_days.to_i > 0
        base_price_monthly = base_plan.price_amount.to_f / (base_plan.duration_days / 30.0).round
      end

      packages = sorted_plans.map do |plan|
        normalized = normalize_subscription_plan(plan)
        
        # Calculate discount correctly
        if base_price_monthly > 0 && plan.duration_days.to_i > 0
          expected_price = base_price_monthly * (plan.duration_days / 30.0).round
          actual_price = plan.price_amount.to_f
          if actual_price < expected_price && expected_price > 0
            discount = ((expected_price - actual_price) / expected_price * 100).round
            normalized[:discount_percent] = discount > 0 ? discount : 0
          else
            normalized[:discount_percent] = 0
          end
        else
          normalized[:discount_percent] = 0
        end
        
        # Determine benefits specifically for this plan
        normalized[:benefits] = generate_benefits(plan)
        
        normalized
      end
      
      tier_rank = PRODUCT_TYPES.index(tier_key) || -1

      {
        tier_name: tier&.name(@account.locale),
        tier_name_en: tier&.name_en,
        tier_name_vi: tier&.name_vi,
        rank: tier_rank,
        description: tier&.description(@account.locale),
        packages: packages
      }
    end
    
    formatted_tiers.sort_by { |t| t[:rank] }
  end

  def trial_data
    sub_plan = SubscriptionPlan.free_plan.visible.first
    normalize_subscription_plan(sub_plan) if sub_plan
  end

  def enterprise_data
    nil
  end

  def normalize_subscription_plan(plan)
    return {} unless plan

    {
      id: plan.id,
      name: plan.name(@account.locale),
      name_en: plan.name_en,
      name_vi: plan.name_vi,
      ai_included: plan.ai_included?,
      price: {
        price_amount: plan.price_amount.to_f,
        currency: plan.currency,
        amount_type: 'paid'
      },
      duration_days: plan.duration_days,
      description: plan.description(@account.locale),
      visible: plan.visible,
      is_free: plan.is_free,
      benefits: generate_benefits(plan)
    }
  end

  LIMIT_KEYS_ORDER = %w[
    inboxes
    agents
    contacts
    automations
    captain_assistants
    captain_responses
    captain_documents
    captain_faqs
  ].freeze

  def generate_benefits(plan)
    categories = []

    # 1. Limitations
    limit_items = []
    LIMIT_KEYS_ORDER.each do |key|
      value = plan.limits[key]
      next if value.blank? || value.to_i <= 0
      limit_items << { id: "limit_#{key}", description: "BILLING_SETTINGS.PRICING_PACKAGES.BENEFITS.LIMITS.#{key.upcase}", count: value, included: true }
    end
    categories << { name: 'BILLING_SETTINGS.PRICING_PACKAGES.BENEFITS.CATEGORIES.LIMITATIONS', items: limit_items } if limit_items.any?

    # 2. Channels
    channel_items = []
    [
      { key: 'channel_website', label: 'WEBSITE' },
      { key: 'channel_zalo', label: 'ZALO_OA' },
      { key: 'channel_zalopersonal', label: 'ZALO_PERSONAL' },
      { key: 'channel_facebook', label: 'FACEBOOK' },
      { key: 'channel_whatsapp', label: 'WHATSAPP' },
      { key: 'channel_instagram', label: 'INSTAGRAM' },
      { key: 'channel_tiktok', label: 'TIKTOK' },
      { key: 'channel_tiktok_shop', label: 'TIKTOK_SHOP' },
      { key: 'channel_telegram', label: 'TELEGRAM' },
      { key: 'channel_line', label: 'LINE' },
      { key: 'channel_twitter', label: 'TWITTER' }
    ].each do |ch|
      if plan.features.is_a?(Hash)
        is_enabled = plan.features[ch[:key]] == "true" || plan.features[ch[:key]] == true
        channel_items << { id: "feature_#{ch[:key]}", description: "BILLING_SETTINGS.PRICING_PACKAGES.BENEFITS.CHANNELS.#{ch[:label]}", included: is_enabled }
      end
    end
    categories << { name: 'BILLING_SETTINGS.PRICING_PACKAGES.BENEFITS.CATEGORIES.CHANNELS', items: channel_items } if channel_items.any?

    # 3. Features
    feature_items = []
    feature_list = [
      { key: ['canned_responses'], label: 'CANNED_RESPONSES' },
      { key: ['macros'], label: 'MACROS' },
      { key: ['automations'], label: 'AUTOMATIONS' },
      { key: ['agent_bots'], label: 'AGENT_BOTS' },
      { key: ['reports'], label: 'REPORTS' },
      { key: ['labels'], label: 'LABELS' },
      { key: ['channel_whatsapp', 'templates'], label: 'CHANNEL_WHATSAPP' },
      { key: ['integrations'], label: 'INTEGRATIONS' },
      { key: ['csat_review_notes', 'csat'], label: 'CSAT_REVIEW_NOTES' },
      { key: ['sla'], label: 'SLA' },
      { key: ['campaigns'], label: 'CAMPAIGNS' },
      { key: ['custom_roles'], label: 'CUSTOM_ROLES' },
      { key: ['custom_attributes'], label: 'CUSTOM_ATTRIBUTES' },
      { key: ['audit_logs'], label: 'AUDIT_LOGS' }
    ]
    
    if plan.features.is_a?(Hash)
      feature_list.each do |feature_map|
        is_enabled = feature_map[:key].any? { |k| plan.features[k] == "true" || plan.features[k] == true }
        feature_items << { id: "feature_#{feature_map[:key].first}", description: "BILLING_SETTINGS.PRICING_PACKAGES.BENEFITS.FEATURES.#{feature_map[:label]}", included: is_enabled }
      end
    end
    categories << { name: 'BILLING_SETTINGS.PRICING_PACKAGES.BENEFITS.CATEGORIES.FEATURES', items: feature_items } if feature_items.any?

    categories
  end
  def all_addon_packages
    AddonPackage.visible.ai_messages.where('price_amount > 0').order(:price_amount).map { |p| normalize_addon_package(p) }
  end

  def normalize_addon_package(addon)
    return {} unless addon

    {
      id: addon.id,
      name: addon.name,
      name_en: addon.name_en,
      name_vi: addon.name_vi,
      price: {
        price_amount: addon.price_amount.to_f,
        currency: addon.currency,
        amount_type: 'paid'
      },
      quantity: addon.quantity,
      addon_type: addon.addon_type,
      visible: addon.visible
    }
  end

  def credit_data
    AddonPackage.ai_messages.visible.order(:price_amount).map do |addon|
      {
        id: addon.id,
        name: addon.name,
        name_en: addon.name_en,
        name_vi: addon.name_vi,
        description: addon.name,
        price: {
          price_amount: addon.price_amount.to_f,
          currency: addon.currency
        }
      }
    end
  end

  def billing_histories_data
    I18n.with_locale(@account.locale || :en) do
      @account.billing_histories.where('price_amount > 0').order(id: :asc).as_json(
        only: [:id, :status, :price_amount],
        methods: [:status_text, :amount_formatted, :created_date_formatted, :content]
      )
    end
  end

  def disabled_register_trial
    @account.billing_histories.where("metadata->>'type' = 'package'").exists?
  end

  def usage_agent
    format_percent(@account.account_users.count, @account.limits['agents'])
  end

  def usage_inbox
    format_percent(@account.inboxes.count, @account.limits['inboxes'])
  end

  def usage_contact
    format_percent(@account.contacts.count, @account.limits['contacts'])
  end

  def usage_automation
    format_percent(@account.automation_rules.count, @account.limits['automations'])
  end

  def usage_captain_document
    format_percent(@account.captain_documents.count, @account.limits['captain_documents'])
  end

  def usage_captain_faq
    format_percent(@account.captain_assistant_responses.count, @account.limits['captain_faqs'])
  end

  def usage_captain_assistant
    format_percent(@account.captain_assistants.count, @account.limits['captain_assistants'])
  end

  def usage_captain_responses
    format_percent(
      @account.custom_attributes['captain_responses_usage'],
      @account.limits['captain_responses']
    )
  end

  def usage_captain_responses_credit
    limit = @account.limits['captain_responses_credit'].to_i
    usage = @account.custom_attributes['captain_responses_credit_usage'].to_i
    remaining = limit - usage
    return nil if limit <= 0
    remaining.to_s
  end

  def format_percent(usage, limit)
    usage = usage.to_i
    limit = limit.to_i
    return 0 if limit.blank?

    [usage, limit].join(' / ')
  end
end
