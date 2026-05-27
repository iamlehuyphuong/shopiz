# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise::Mailer' do
  describe 'notify' do
    let(:account) { create(:account) }
    let!(:confirmable_user) { create(:user, inviter: inviter_val, account: account) }
    let(:inviter_val) { nil }
    let(:confirmation_token) { confirmable_user.instance_variable_get(:@raw_confirmation_token) || confirmable_user.confirmation_token }

    before do
      # to verify the token in email
      confirmable_user.update!(confirmed_at: nil)
      confirmable_user.send(:generate_confirmation_token)
    end

    it 'has the correct header data' do
      mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, confirmation_token, {})
      expect(mail.to).to contain_exactly(confirmable_user.email)
      expect(mail.subject).to eq('Confirmation Instructions')
    end

    it 'uses the user\'s name' do
      mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, confirmation_token, {})
      user_drop_name = confirmable_user.name.split.map(&:capitalize).join(' ')
      expect(mail.body.to_s).to include("Hi <strong>#{user_drop_name}</strong>")
    end

    it 'contains welcome content' do
      mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, confirmation_token, {})
      expect(mail.body.to_s).to include('Welcome to Flowify!')
      expect(mail.body.to_s).to include('powerful customer engagement toolkit')
    end

    it 'sends a confirmation link' do
      mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, confirmation_token, {})
      expect(mail.body.to_s).to include("app/auth/confirmation?confirmation_token=#{confirmation_token}")
    end

    it 'contains verify email button' do
      mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, confirmation_token, {})
      expect(mail.body.to_s).to include('Verify Email')
    end

    context 'when user updates the email' do
      before do
        confirmable_user.update!(email: 'user@example.com')
      end

      it 'sends a confirmation link' do
        updated_user = confirmable_user.reload
        token = updated_user.instance_variable_get(:@raw_confirmation_token) || updated_user.confirmation_token
        confirmation_mail = Devise::Mailer.confirmation_instructions(updated_user, token, {})

        expect(confirmation_mail.body.to_s).to include('app/auth/confirmation?confirmation_token')
        expect(confirmable_user.unconfirmed_email.blank?).to be false
      end
    end

    context 'when user is confirmed and updates the email' do
      before do
        confirmable_user.confirm
        confirmable_user.update!(email: 'user@example.com')
      end

      it 'sends a confirmation link' do
        updated_user = confirmable_user.reload
        token = updated_user.instance_variable_get(:@raw_confirmation_token) || updated_user.confirmation_token
        confirmation_mail = Devise::Mailer.confirmation_instructions(updated_user, token, {})

        expect(confirmation_mail.body.to_s).to include('app/auth/confirmation?confirmation_token')
        expect(confirmable_user.unconfirmed_email.blank?).to be false
      end
    end
  end
end
