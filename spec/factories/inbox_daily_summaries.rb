FactoryBot.define do
  factory :inbox_daily_summary do
    account { nil }
    inbox { nil }
    enabled { false }
    nlp_prompt { "MyText" }
    schedule_times { "" }
    last_run_at { "2026-07-01 20:01:43" }
  end
end
