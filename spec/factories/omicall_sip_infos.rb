FactoryBot.define do
  factory :omicall_sip_info do
    account { nil }
    user { nil }
    sip_user { "MyString" }
    sip_password { "MyString" }
    sip_domain { "MyString" }
    outbound_proxy { "MyString" }
  end
end
