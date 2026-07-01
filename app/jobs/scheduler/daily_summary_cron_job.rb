module Scheduler
  class DailySummaryCronJob < ApplicationJob
    queue_as :scheduled_jobs

    def perform
      InboxDailySummary.where(enabled: true).find_each do |summary_config|
        next if summary_config.schedule_times.blank?

        timezone = summary_config.timezone.presence || summary_config.account.timezone || 'UTC'
        current_time = Time.current.in_time_zone(timezone)
        
        # This job runs every 15 minutes. Check if any schedule time falls in the last 15 mins.
        should_run = summary_config.schedule_times.any? do |time_str|
          # time_str is e.g. "08:00"
          hour, min = time_str.split(':').map(&:to_i)
          scheduled_time = current_time.change(hour: hour, min: min)
          
          # Check if scheduled time is between 15 minutes ago and now
          scheduled_time > 15.minutes.ago.in_time_zone(timezone) && scheduled_time <= current_time
        end

        if should_run
          Captain::GenerateDailySummaryJob.perform_later(summary_config.id)
        end
      end
    end
  end
end
