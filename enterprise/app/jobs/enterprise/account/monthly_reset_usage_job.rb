class Enterprise::Account::MonthlyResetUsageJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.active.joins(:active_subscription).find_each do |account|
      next unless should_reset_usage?(account)

      account.reset_response_usage
    end
  end

  private

  def should_reset_usage?(account)
    sub = account.active_subscription
    return false unless sub&.active?

    reset_day = sub.starts_at.day
    today = Time.zone.today

    # Today is the day of the month the subscription started
    return true if today.day == reset_day

    # Handling months with fewer days than reset_day (e.g., reset_day is 31, today is Feb 28/29 or April 30)
    return true if today.day < reset_day && today == today.end_of_month

    false
  end
end
