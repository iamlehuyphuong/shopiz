# frozen_string_literal: true

class Subscriptions::ProvisioningService
  def initialize(account)
    @account = account
  end

  def execute
    active_subscription = @account.active_subscription
    
    if active_subscription.nil?
      reset_to_defaults
      return
    end

    plan = active_subscription.subscription_plan
    addons = @account.account_addons.active

    ActiveRecord::Base.transaction do
      check_and_reset_monthly_usage
      apply_limits(plan, addons)
      apply_features(plan)
      apply_custom_attributes(active_subscription, plan)
      @account.save!
    end
  end

  private

  def check_and_reset_monthly_usage
    # We use the current month and year to determine if a reset is needed
    # This is a simple implementation that resets at the start of every calendar month
    # A more complex one would use the subscription billing day.
    current_period = Time.current.strftime('%Y-%m')
    last_reset_period = @account.custom_attributes['last_captain_reset_period']

    if last_reset_period != current_period
      @account.reset_response_usage
      @account.custom_attributes['last_captain_reset_period'] = current_period
    end
  end

  private

  def reset_to_defaults
    default_plan = SubscriptionPlan.free_plan.first
    
    if default_plan
      Rails.logger.info "Resetting Account #{@account.id} to default plan: #{default_plan.name_en}"
      apply_limits(default_plan, [])
      apply_features(default_plan)
      apply_custom_attributes(OpenStruct.new(status: 'expired', ends_at: Time.current), default_plan)
      @account.save!
      return
    end

    # Fallback to hardcoded defaults if no free plan is configured in DB
    default_limits = {
      'agents' => 2,
      'inboxes' => 2,
      'captain_responses' => 0,
      'captain_documents' => 0,
      'captain_assistants' => 0,
      'captain_faqs' => 0,
      'contacts' => 1000,
      'automations' => 0
    }
    
    @account.assign_attributes(limits: default_limits)
    # Disable premium features
    @account.disable_features(*Featurable::MAPPING.values)
    @account.enable_features(*Featurable::DEFAULT_PLAN_FEATURES)
    
    current_attrs = @account.custom_attributes || {}
    @account.assign_attributes(custom_attributes: current_attrs.merge({
      'plan_name' => 'free',
      'subscription_status' => 'expired',
      'subscription_ends_on' => nil
    }))
    @account.save!
  end

  def apply_limits(plan, addons)
    base_limits = plan.limits || {}
    
    # Initialize limits with base plan limits
    final_limits = {
      'agents' => base_limits['agents'].to_i,
      'inboxes' => base_limits['inboxes'].to_i,
      'captain_responses' => base_limits['captain_responses'].to_i,
      'captain_responses_credit' => base_limits['captain_responses_credit'].to_i,
      'captain_documents' => base_limits['captain_documents'].to_i,
      'captain_assistants' => base_limits['captain_assistants'].to_i,
      'captain_faqs' => base_limits['captain_faqs'].to_i,
      'contacts' => base_limits['contacts'].to_i,
      'automations' => base_limits['automations'].to_i
    }

    # Add resources from addons
    addons.each do |addon|
      case addon.addon_type
      when 'ai_messages'
        final_limits['captain_responses_credit'] += addon.quantity
      when 'staff'
        final_limits['agents'] += addon.quantity
      when 'inboxes_count'
        final_limits['inboxes'] += addon.quantity
      end
    end

    @account.assign_attributes(limits: final_limits)
  end

  def apply_features(plan)
    plan_features = plan.features || {}
    
    # Get all available features from Featurable
    all_feature_names = Featurable::FEATURE_LIST.map { |f| f['name'] }
    
    features_to_enable = []
    features_to_disable = []

    all_feature_names.each do |feature_name|
      is_enabled = ActiveModel::Type::Boolean.new.cast(plan_features[feature_name])
      if is_enabled
        features_to_enable << feature_name.to_sym
      else
        features_to_disable << feature_name.to_sym
      end
    end

    Rails.logger.info "Provisioning features for Account #{@account.id} (Plan: #{plan.name_en}): Enabling #{features_to_enable.size}, Disabling #{features_to_disable.size}"
    
    @account.enable_features(*features_to_enable)
    @account.disable_features(*features_to_disable)
  end

  def apply_custom_attributes(subscription, plan)
    # Sync with current custom attributes structure to maintain compatibility
    current_attrs = @account.custom_attributes || {}
    updated_attrs = current_attrs.merge({
      'plan_name' => plan.name_en.downcase,
      'subscription_status' => subscription.status,
      'subscription_ends_on' => subscription.ends_at.to_date.to_s,
      'sku' => "PLAN_#{plan.id}"
    })

    @account.assign_attributes(custom_attributes: updated_attrs)
  end
end
