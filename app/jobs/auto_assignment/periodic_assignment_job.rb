class AutoAssignment::PeriodicAssignmentJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_in_batches do |accounts|
      accounts.each do |account|
        next unless account.feature_enabled?('advanced_assignment')

        account.inboxes.joins(:assignment_policy).find_in_batches do |inboxes|
          inboxes.each do |inbox|
            next unless inbox.advanced_assignment_enabled?

            AutoAssignment::AssignmentJob.perform_later(inbox_id: inbox.id)
          end
        end
      end
    end
  end
end
