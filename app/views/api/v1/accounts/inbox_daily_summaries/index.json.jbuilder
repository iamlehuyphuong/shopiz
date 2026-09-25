json.array! @summaries do |summary|
  json.extract! summary, :id, :account_id, :inbox_ids, :enabled, :summary_instruction, :reporting_instruction, :schedule_times, :user_ids, :timezone,
                :last_run_at, :created_at, :updated_at
end
