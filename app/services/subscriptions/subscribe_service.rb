# frozen_string_literal: true

class Subscriptions::SubscribeService
  def initialize(account, plan)
    @account = account
    @plan = plan
  end

  def execute
    ActiveRecord::Base.transaction do
      deactivate_current_subscriptions
      create_new_subscription
      update_account_resources
      log_transaction
    end
    true
  rescue StandardError => e
    Rails.logger.error("Subscription Error: #{e.message}")
    false
  end

  private

  def deactivate_current_subscriptions
    @account.account_subscriptions.active.update_all(status: :expired, updated_at: Time.current)
  end

  def create_new_subscription
    @subscription = @account.account_subscriptions.create!(
      subscription_plan: @plan,
      starts_at: Time.current,
      ends_at: @plan.is_free? ? nil : Time.current + @plan.duration_days.days,
      status: :active
    )
  end

  def update_account_resources
    Subscriptions::ProvisioningService.new(@account).execute
  end

  def log_transaction
    BillingHistory.create!(
      account: @account,
      product_id: "PLAN_#{@plan.id}",
      product_name: @plan.name_en,
      sku: "PLAN_#{@plan.id}",
      price_amount: @plan.price_amount,
      price_currency: @plan.currency,
      status: :invoiced,
      transaction_date_time: Time.current.to_s,
      description: "Subscription to #{@plan.name_en} (#{@plan.duration_days} days)",
      metadata: { 
        type: 'subscription',
        plan_id: @plan.id,
        duration: @plan.duration_days
      }
    )
  end
end
