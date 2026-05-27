# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise::Mailer' do
  describe 'confirmation_instructions with Enterprise features' do
    let(:account) { create(:account) }
    let!(:confirmable_user) { create(:user, inviter: inviter_val, account: account) }
    let(:inviter_val) { nil }

    before do
      confirmable_user.update!(confirmed_at: nil)
      confirmable_user.send(:generate_confirmation_token)
    end

    context 'with SAML enabled account' do
      let(:saml_settings) { create(:account_saml_settings, account: account) }

      before { saml_settings }

      context 'when user has no inviter' do
        it 'shows welcome message' do
          token = confirmable_user.instance_variable_get(:@raw_confirmation_token) || confirmable_user.confirmation_token
          mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, token, {})
          expect(mail.body.to_s).to include('Welcome to Flowify!')
        end

        it 'shows confirmation link' do
          token = confirmable_user.instance_variable_get(:@raw_confirmation_token) || confirmable_user.confirmation_token
          mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, token, {})
          expect(mail.body.to_s).to include("app/auth/confirmation?confirmation_token=#{token}")
        end
      end

      context 'when user updates email on SAML account' do
        let(:inviter_val) { create(:user, :administrator, skip_confirmation: true, account: account) }

        before do
          confirmable_user.update!(email: 'updated@example.com')
        end

        it 'still shows confirmation link for email verification' do
          updated_user = confirmable_user.reload
          token = updated_user.instance_variable_get(:@raw_confirmation_token) || updated_user.confirmation_token
          updated_mail = Devise::Mailer.confirmation_instructions(updated_user, token, {})
          expect(updated_mail.body.to_s).to include('app/auth/confirmation?confirmation_token')
          expect(confirmable_user.unconfirmed_email.blank?).to be false
        end
      end
    end

    context 'when account does not have SAML enabled' do
      context 'when user has no inviter' do
        it 'shows welcome message and verify email button' do
          token = confirmable_user.instance_variable_get(:@raw_confirmation_token) || confirmable_user.confirmation_token
          mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, token, {})
          expect(mail.body.to_s).to include('Welcome to Flowify!')
          expect(mail.body.to_s).to include('Verify Email')
        end

        it 'shows confirmation link' do
          token = confirmable_user.instance_variable_get(:@raw_confirmation_token) || confirmable_user.confirmation_token
          mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, token, {})
          expect(mail.body.to_s).to include("app/auth/confirmation?confirmation_token=#{token}")
        end
      end

      context 'when user updates email' do
        before do
          confirmable_user.update!(email: 'updated@example.com')
        end

        it 'shows confirmation link for email verification' do
          updated_user = confirmable_user.reload
          token = updated_user.instance_variable_get(:@raw_confirmation_token) || updated_user.confirmation_token
          updated_mail = Devise::Mailer.confirmation_instructions(updated_user, token, {})
          expect(updated_mail.body.to_s).to include('app/auth/confirmation?confirmation_token')
          expect(confirmable_user.unconfirmed_email.blank?).to be false
        end
      end
    end
  end
end
