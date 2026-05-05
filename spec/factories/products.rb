FactoryBot.define do
  factory :product do
    account { nil }
    name { "MyString" }
    description { "MyText" }
    price { "9.99" }
    currency { "MyString" }
    sku { "MyString" }
    barcode { "MyString" }
    status { 1 }
    external_id { "MyString" }
    meta { "" }
  end
end
