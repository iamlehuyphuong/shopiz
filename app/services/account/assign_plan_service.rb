# frozen_string_literal: true

class Account::AssignPlanService
  def initialize(account, plan_id)
    @account = account
    @plan_id = plan_id
    @plan = load_plan
  end

  def execute
    return unless @plan

    ActiveRecord::Base.transaction do
      update_account_attributes
      change_plan_features
      update_limits
    end
    true
  rescue StandardError => e
    Rails.logger.error("Failed to assign plan #{@plan_id} to account #{@account.id}: #{e.message}")
    false
  end

  private

  def load_plan
    SubscriptionPlan.find_by(id: @plan_id)
  end

  def update_account_attributes
    custom_attributes = {
      stripe_customer_id: @account.id,
      stripe_price_id: nil, # No longer using Stripe/Polar price IDs here
      stripe_product_id: @plan_id,
      plan_name: @plan.name(@account.locale),
      sku: @plan.sku,
      subscribed_quantity: @plan.limits['agents'],
      subscription_status: 'active',
      subscription_ends_on: subscription_ends_on
    }

    @account.update(custom_attributes: @account.custom_attributes.merge(custom_attributes))
  end

  def subscription_ends_on
    (Time.zone.now + @plan.duration_days.days).to_s
  end

  def change_plan_features
    # Disable all current features before applying plan-specific ones
    all_feature_names = Featurable::FEATURE_LIST.map { |f| f['name'] }
    @account.disable_features(*all_feature_names)

    if default_plan?
      @account.enable_features(*Featurable::DEFAULT_PLAN_FEATURES)
    else
      @plan.features.each do |feature, enabled|
        enabled ? @account.enable_features(feature) : @account.disable_features(feature)
      end
    end
    @account.save!
  end

  def update_limits
    @account.update!(limits: @account.limits.merge(@plan.limits))
  end

  def reset_captain_usage
    @account.reset_response_usage
  end

  def default_plan?
    @plan.is_free?
  end
end
