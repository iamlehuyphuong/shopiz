FactoryBot.define do
  factory :booking do
    account { nil }
    contact { nil }
    conversation { nil }
    start_time { '2026-07-14 21:54:58' }
    end_time { '2026-07-14 21:54:58' }
    guest_name { 'MyString' }
    guest_email { 'MyString' }
    google_event_id { 'MyString' }
    provider { 'MyString' }
    status { 1 }
  end
end
