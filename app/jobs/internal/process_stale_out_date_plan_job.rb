# Internal::ProcessStaleOutDatePlanJob
#
# This job iterates over all accounts in batches to update feature settings based on subscription dates.
#
# For each account, the job:
#   - Retrieves the 'subscription_ends_on' value from the account's custom attributes.
#   - Skips the account if 'subscription_ends_on' is not set.
#   - Compares the parsed subscription end date with today's date.
#   - If the subscription end date is in the past, it set free plan for account.
#
# The job is executed on the 'scheduled_jobs' queue.

class Internal::ProcessStaleOutDatePlanJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_in_batches do |accounts|
      accounts.each do |account|
        subscription_ends_on = account.custom_attributes['subscription_ends_on']
        next if subscription_ends_on.blank?

        if Time.zone.today > Date.parse(subscription_ends_on.to_s)
          account.assign_free_plan
        end
      end
    end
  end
end
