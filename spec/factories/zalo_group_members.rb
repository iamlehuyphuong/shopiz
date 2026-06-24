FactoryBot.define do
  factory :zalo_group_member do
    account { nil }
    conversation { nil }
    uid { "MyString" }
    name { "MyString" }
    avatar { "MyString" }
    cover { "MyString" }
    bio { "MyString" }
    gender { "MyString" }
    dob { "MyString" }
    is_creator { false }
    is_admin { false }
  end
end
