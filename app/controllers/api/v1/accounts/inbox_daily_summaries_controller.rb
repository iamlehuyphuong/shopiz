class Api::V1::Accounts::InboxDailySummariesController < Api::V1::Accounts::BaseController
  def index
    @summary = Current.account.inbox_daily_summaries.first_or_create(
      instruction: "Tổng hợp các ý chính từ các cuộc trò chuyện.",
      schedule_times: [],
      user_ids: [],
      inbox_ids: [],
      enabled: false
    )
    
    render 'api/v1/accounts/inbox_daily_summaries/show'
  end

  def update
    @summary = Current.account.inbox_daily_summaries.first_or_initialize
    
    if @summary.update(summary_params)
      render 'api/v1/accounts/inbox_daily_summaries/show'
    else
      render json: { error: @summary.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def summary_params
    params.require(:inbox_daily_summary).permit(
      :enabled,
      :summary_instruction,
      :reporting_instruction,
      :timezone,
      user_ids: [],
      schedule_times: [],
      inbox_ids: []
    )
  end
end
