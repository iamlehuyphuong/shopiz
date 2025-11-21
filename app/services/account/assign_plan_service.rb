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
  rescue StandardError
    false
  end

  private

  def load_plan
    Polar::ProductService.find(@plan_id)
  rescue StandardError
    nil
  end

  def update_account_attributes
    custom_attributes = {
      stripe_customer_id: @account.id,
      stripe_price_id: @plan[:prices][0]['id'],
      stripe_product_id: @plan_id,
      plan_name: @plan[:name],
      sku: @plan[:metadata]['sku'],
      subscribed_quantity: @plan.dig(:metadata, 'agents'),
      subscription_status: 'active',
      subscription_ends_on: subscription_ends_on
    }

    @account.update(custom_attributes: custom_attributes)
  end

  def subscription_ends_on
    current_plan = @account.custom_attributes['plan_name']
    number_of_months = @plan[:metadata]['months'].to_i

    if current_plan == @plan[:name]
      base_time = [Time.zone.now, Time.zone.parse(@account.custom_attributes['subscription_ends_on'])].max
      base_time + number_of_months.months
    else
      Time.zone.now + number_of_months.months
    end
  end

  def change_plan_features
    @account.disable_features(*Featurable::MAPPING.values)

    if default_plan?
      @account.enable_features(*Featurable::DEFAULT_PLAN_FEATURES)
    else
      features = @plan.dig(:metadata, 'features')&.split(',')&.map(&:strip) || []
      mapping_features = features.map { |item| Featurable::MAPPING[item.to_sym] }
      @account.enable_features(*mapping_features)
    end
    @account.save!
  end

  def update_limits
    @account.limits = build_limits
    @account.save!
  end

  def build_limits
    metadata = @plan[:metadata]

    {
      captain_assistants: metadata['captain_assistants'].to_i,
      captain_responses: metadata['captain_responses'].to_i,
      captain_documents: metadata['captain_documents'].to_i,
      captain_faqs: metadata['captain_faqs'].to_i,
      contacts: metadata['contacts'].to_i,
      inboxes: metadata['inboxes'].to_i,
      agents: metadata['agents'].to_i,
      automations: metadata['automations'].to_i
    }
  end

  def reset_captain_usage
    @account.reset_response_usage
  end

  def default_plan?
    @account.custom_attributes['plan_name'] == 'free'
  end
end
