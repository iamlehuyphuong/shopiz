# frozen_string_literal: true

class Enterprise::Billing::CreateVnpayCustomerService
  pattr_initialize [:account!]

  def perform
    # Assign the free plan from DB if account doesn't have an active subscription
    return if account.active_subscription.present?

    free_plan = SubscriptionPlan.free_plan.first
    return if free_plan.blank?

    Subscriptions::SubscribeService.new(account, free_plan).execute
  end
end
