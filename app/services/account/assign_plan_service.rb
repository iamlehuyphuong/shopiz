# frozen_string_literal: true

class Account::AssignPlanService
  FEATURES_TO_UPDATE = %w[
    inbound_emails
    help_center
    campaigns
    team_management
    channel_twitter
    channel_facebook
    channel_email
    channel_api
    channel_zalopersonal
    channel_line
    channel_telegram
    channel_whatsapp
    captain_integration
  ].freeze

  def initialize(account, plan_id)
    @account = account
    @plan_id = plan_id
    @plan = load_plan
    binding.pry
  end

  def execute
    return unless @plan

    ActiveRecord::Base.transaction do
      update_account_attributes
      change_plan_features
      update_limits
      reset_captain_usage
    end
    true
  rescue StandardError
    false
  end

  private

  def load_plan
    Polar.configure do |config|
      config.access_token = ENV.fetch('POLAR_ACCESS_TOKEN')
      config.sandbox = ENV.fetch('POLAR_ENV') == 'sandbox'
    end

    Polar::Product.get(@plan_id).table
  rescue StandardError
    nil
  end

  def update_account_attributes
    days = (@plan.dig(:metadata, 'months').to_i || 0) * 30
    custom_attributes = {
      stripe_customer_id: @account.id,
      stripe_price_id: @plan[:prices][0]['id'],
      stripe_product_id: @plan_id,
      plan_name: @plan[:name],
      subscribed_quantity: @plan.dig(:metadata, 'agents'),
      subscription_status: 'active',
      subscription_ends_on: Time.zone.at(Time.now.to_i + days.days),
    }

    @account.update(custom_attributes: custom_attributes)
  end

  def change_plan_features
    if default_plan?
      @account.disable_features(*FEATURES_TO_UPDATE)
    else
      features = @plan.dig(:metadata, 'features')&.split(',')&.map(&:strip) || []
      @account.enable_features(*features)
    end
    @account.save!
  end

  def update_limits
    limits = {
      'inboxes' => @plan.dig(:metadata, 'inboxes') || 1,
      'agents' => @plan.dig(:metadata, 'agents') || 1,
      'captain_responses' => @plan.dig(:metadata, 'captain_responses') || 0,
      'captain_documents' => @plan.dig(:metadata, 'captain_documents') || 0
    }
    @account.limits = limits
    @account.save!
  end

  def reset_captain_usage
    @account.reset_response_usage
  end

  def default_plan?
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    default_plan = installation_config.value.first
    @account.custom_attributes['plan_name'] == default_plan['name']
  end
end
