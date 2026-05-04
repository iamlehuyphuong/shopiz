# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_order do
    status { :draft }
    customer_name { 'Nguyễn Văn A' }
    customer_phone { '0901234567' }
    customer_address { '123 Đường ABC, Quận 1, TP.HCM' }
    currency { 'VND' }

    after(:build) do |order|
      order.account ||= create(:account)
      order.conversation ||= create(:conversation, account: order.account)
      order.contact ||= order.conversation.contact
    end

    trait :with_items do
      after(:create) do |order|
        create_list(:conversation_order_item, 2, conversation_order: order)
        order.reload
      end
    end

    trait :confirmed do
      status { :confirmed }
      external_order_id { "EXT-#{SecureRandom.hex(4)}" }
      external_source { 'kiotviet' }
    end

    trait :pushed do
      status { :confirmed }
      external_order_id { "EXT-#{SecureRandom.hex(4)}" }
      external_source { 'kiotviet' }
    end

    trait :delivered do
      status { :delivered }
      external_order_id { "EXT-#{SecureRandom.hex(4)}" }
      external_source { 'kiotviet' }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
