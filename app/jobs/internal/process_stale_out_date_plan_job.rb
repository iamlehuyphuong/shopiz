# Internal::ProcessStaleOutDatePlanJob
#
# This job iterates over all accounts in batches to handle expired subscriptions.
#
# For each account, the job:
#   - Checks the active_subscription record from account_subscriptions table.
#   - If no active subscription exists, checks custom_attributes['subscription_ends_on'] for legacy data.
#   - If the subscription has expired beyond the grace period (3 days), assigns the free plan.
#
# The job is executed on the 'scheduled_jobs' queue.

class Internal::ProcessStaleOutDatePlanJob < ApplicationJob
  queue_as :scheduled_jobs

  GRACE_PERIOD_DAYS = 3

  def perform
    process_expired_subscriptions
    process_legacy_expired_accounts
  end

  private

  def process_expired_subscriptions
    # Find active subscriptions that have expired beyond the grace period
    AccountSubscription.where(status: :active)
                       .where('ends_at < ?', Time.current - GRACE_PERIOD_DAYS.days)
                       .find_each do |subscription|
      subscription.update!(status: :expired)
      assign_free_plan(subscription.account)
    end
  end

  def process_legacy_expired_accounts
    # Handle accounts that still use custom_attributes for subscription tracking
    Account.find_in_batches do |accounts|
      accounts.each do |account|
        # Skip if account already has an active subscription record
        next if account.active_subscription.present?

        subscription_ends_on = account.custom_attributes['subscription_ends_on']
        next if subscription_ends_on.blank?

        ends_on = Date.parse(subscription_ends_on.to_s)
        grace_end = ends_on + GRACE_PERIOD_DAYS.days

        assign_free_plan(account) if Time.zone.today > grace_end
      rescue Date::Error
        Rails.logger.warn("Invalid subscription_ends_on for Account #{account.id}: #{subscription_ends_on}")
      end
    end
  end

  def assign_free_plan(account)
    free_plan = SubscriptionPlan.free_plan.first
    return unless free_plan

    Subscriptions::SubscribeService.new(account, free_plan).execute
    Rails.logger.info("Account #{account.id} downgraded to free plan after grace period expired")
  end
end
