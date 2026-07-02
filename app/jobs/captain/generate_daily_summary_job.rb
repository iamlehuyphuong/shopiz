class Captain::GenerateDailySummaryJob < ApplicationJob
  queue_as :default

  def perform(inbox_daily_summary_id)
    summary_config = InboxDailySummary.find_by(id: inbox_daily_summary_id)
    return unless summary_config&.enabled

    Captain::GenerateDailySummaryService.new(
      account: summary_config.account,
      inbox_daily_summary: summary_config
    ).perform
  end
end
