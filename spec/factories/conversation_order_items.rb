# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_order_item do
    conversation_order
    product_name { "Sản phẩm #{SecureRandom.hex(3)}" }
    quantity { 2 }
    unit_price { 150_000 }
    product_id { "PROD-#{SecureRandom.hex(4)}" }
  end
end
