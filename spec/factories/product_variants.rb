FactoryBot.define do
  factory :product_variant do
    account { nil }
    product { nil }
    name { "MyString" }
    sku { "MyString" }
    barcode { "MyString" }
    price { "9.99" }
    compare_at_price { "9.99" }
    inventory_quantity { 1 }
    weight { "9.99" }
    external_id { "MyString" }
    meta { "" }
  end
end
