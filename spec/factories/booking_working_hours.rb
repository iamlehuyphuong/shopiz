FactoryBot.define do
  factory :booking_working_hour do
    booking_configuration { nil }
    day_of_week { 1 }
    open_hour { 1 }
    open_minutes { 1 }
    close_hour { 1 }
    close_minutes { 1 }
    closed_all_day { false }
    open_all_day { false }
  end
end
