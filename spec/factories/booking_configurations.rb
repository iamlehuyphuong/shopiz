FactoryBot.define do
  factory :booking_configuration do
    account { nil }
    meeting_duration { 1 }
    buffer_time { 1 }
    booking_link_hash { "MyString" }
    is_active { false }
  end
end
