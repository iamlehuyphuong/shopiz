# frozen_string_literal: true

class Subscriptions::ExpirationJob < ApplicationJob
  queue_as :scheduled_jobs

  GRACE_PERIOD_DAYS = 3

  def perform
    mark_expired_subscriptions
    downgrade_after_grace_period
    expire_addons
  end

  private

  def mark_expired_subscriptions
    # Mark subscriptions as expired when ends_at has passed
    # But DON'T downgrade yet - they get a 3-day grace period
    # Skip free plans - they never expire (ends_at is nil)
    AccountSubscription.where(status: :active)
                       .where.not(ends_at: nil)
                       .where('ends_at < ?', Time.current)
                       .joins(:subscription_plan).where.not(subscription_plans: { subscription_tier_id: SubscriptionTier.where(is_free: true).select(:id) })
                       .find_each do |subscription|
      subscription.update!(status: :expired)
      Rails.logger.info("Subscription #{subscription.id} for Account #{subscription.account_id} marked as expired (grace period starts)")
    end
  end

  def downgrade_after_grace_period
    # Find expired subscriptions where grace period has also passed
    # Free plans have ends_at=nil, so they're naturally excluded
    AccountSubscription.where(status: :expired)
                       .where.not(ends_at: nil)
                       .where('ends_at < ?', Time.current - GRACE_PERIOD_DAYS.days)
                       .find_each do |subscription|
      account = subscription.account
      # Skip if account already has a newer active subscription
      next if account.active_subscription.present?

      free_plan = SubscriptionPlan.free_plan.first
      next unless free_plan

      Subscriptions::SubscribeService.new(account, free_plan).execute
      Rails.logger.info("Account #{account.id} downgraded to free plan after #{GRACE_PERIOD_DAYS}-day grace period")
    end
  end

  def expire_addons
    # Find active addons with an expiration date that has passed
    AccountAddon.active.where('expired_at < ?', Time.current).find_each do |addon|
      Subscriptions::ProvisioningService.new(addon.account).execute
    end
  end
end
