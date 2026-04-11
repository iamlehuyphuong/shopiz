# frozen_string_literal: true

class Enterprise::Billing::HandleStripeEventService
  def perform(event:)
    @event = event

    case @event.type
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def process_subscription_updated
    return if account.blank?

    # Try to find the plan by SKU from metadata, or by Stripe product_id
    plan = find_plan_from_event
    return if plan.blank?

    ActiveRecord::Base.transaction do
      Subscriptions::SubscribeService.new(account, plan).execute
    end
  end

  def process_subscription_deleted
    return if account.blank?

    # When Stripe subscription is deleted, downgrade to free plan
    free_plan = SubscriptionPlan.free_plan.first
    return unless free_plan

    Subscriptions::SubscribeService.new(account, free_plan).execute
  end

  def find_plan_from_event
    # 1. Try SKU from Stripe subscription metadata
    sku = subscription.dig('metadata', 'sku')
    plan = SubscriptionPlan.find_by(sku: sku) if sku.present?
    return plan if plan.present?

    # 2. Try product_id from Stripe
    product_id = subscription.dig('plan', 'product')
    if product_id.present?
      plan = SubscriptionPlan.find_by(sku: product_id)
      return plan if plan.present?
    end

    # 3. Fallback: try price_id
    price_id = subscription.dig('plan', 'id')
    if price_id.present?
      plan = SubscriptionPlan.find_by(sku: price_id)
      return plan if plan.present?
    end

    Rails.logger.warn("Could not find SubscriptionPlan for Stripe event. SKU: #{sku}, product: #{product_id}, price: #{price_id}")
    nil
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= begin
      # Try to find by stripe_customer_id in custom_attributes
      customer_id = subscription.customer
      Account.where("custom_attributes->>'stripe_customer_id' = ?", customer_id).first ||
        Account.find_by(id: customer_id)
    end
  end
end
