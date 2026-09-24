# frozen_string_literal: true

FactoryBot.define do
  factory :contact_inbox do
    contact
    inbox

    after(:build) { |contact_inbox| contact_inbox.source_id ||= generate_source_id(contact_inbox) }
  end
end

def generate_source_id(contact_inbox)
  case contact_inbox.inbox.channel_type
  when 'Channel::Whatsapp'
    Faker::PhoneNumber.cell_phone_in_e164.delete('+')
  else
    SecureRandom.uuid
  end
end
