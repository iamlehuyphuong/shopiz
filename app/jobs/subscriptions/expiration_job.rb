# frozen_string_literal: true

class Subscriptions::ExpirationJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    expire_subscriptions
    expire_addons
  end

  private

  def expire_subscriptions
    AccountSubscription.active.where('ends_at < ?', Time.current).find_each do |subscription|
      subscription.update!(status: :expired)
      Subscriptions::ProvisioningService.new(subscription.account).execute
      
      # Optional: Notify account admins about expiration
      # Rails.configuration.dispatcher.dispatch(ACCOUNT_SUBSCRIPTION_EXPIRED, Time.zone.now, account: subscription.account)
    end
  end

  def expire_addons
    # Find active addons with an expiration date that has passed
    AccountAddon.active.where('expired_at < ?', Time.current).find_each do |addon|
      # Since we don't have a status on AccountAddon, we just need to re-provision
      # the account. The active scope will automatically exclude these once expired_at is in the past.
      Subscriptions::ProvisioningService.new(addon.account).execute
    end
  end
end
