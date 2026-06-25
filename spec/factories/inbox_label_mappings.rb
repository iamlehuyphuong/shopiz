FactoryBot.define do
  factory :inbox_label_mapping do
    inbox { nil }
    label { nil }
    native_label_id { 'some_id' }
    native_label_name { 'some_name' }
  end
end
