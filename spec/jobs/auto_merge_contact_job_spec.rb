require 'rails_helper'

RSpec.describe AutoMergeContactJob, type: :job do
  let(:account) { create(:account) }
  let(:phone_number) { '+1234567890' }
  let(:email) { 'test@example.com' }
  let(:older_contact) { create(:contact, account: account, phone_number: '+111', created_at: 2.days.ago) }
  let(:newer_contact) { create(:contact, account: account, phone_number: '+222', created_at: 1.day.ago) }

  describe '#perform' do
    it 'does not raise error if contact does not exist' do
      expect { described_class.perform_now(-1) }.not_to raise_error
    end

    context 'when matching contact exists' do
      it 'merges newer contact into older contact' do
        allow(Contact).to receive(:find_by).with(id: newer_contact.id).and_return(newer_contact)
        job_instance = described_class.new(newer_contact.id)
        allow(job_instance).to receive(:find_target_contact).with(newer_contact).and_return(older_contact)

        expect(ContactMergeAction).to receive(:new).with(
          account: account,
          base_contact: older_contact,
          mergee_contact: newer_contact
        ).and_call_original

        job_instance.perform_now
      end
    end

    context 'when finding targets' do
      it 'prioritizes the oldest contact among matches' do
        job = described_class.new
        older_email_contact = create(:contact, account: account, email: email, created_at: 3.days.ago)
        older_phone_contact = create(:contact, account: account, phone_number: phone_number, created_at: 2.days.ago)
        
        # We can mock the contact to return the matching values without hitting DB unique index constraints for the same account
        contact = double('Contact', id: 999, account_id: account.id, phone_number: phone_number, email: email)
        
        target = job.send(:find_target_contact, contact)
        expect(target.id).to eq(older_email_contact.id)
      end
    end

    context 'when handling errors' do
      it 'rescues ActiveRecord::RecordInvalid without throwing an exception' do
        allow(Contact).to receive(:find_by).with(id: newer_contact.id).and_return(newer_contact)
        job_instance = described_class.new(newer_contact.id)
        allow(job_instance).to receive(:find_target_contact).with(newer_contact).and_return(older_contact)

        action_double = instance_double(ContactMergeAction)
        allow(ContactMergeAction).to receive(:new).and_return(action_double)
        allow(action_double).to receive(:perform).and_raise(ActiveRecord::RecordInvalid.new(newer_contact))

        expect(Rails.logger).to receive(:warn).with(/\[AutoMerge\] Skipped merge for Contact##{newer_contact.id}/)
        expect { job_instance.perform_now }.not_to raise_error
      end
    end
  end
end
