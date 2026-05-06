# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::Kiotviet', type: :request do
  let(:account) { create(:account) }

  before do
    allow(GlobalConfigService).to receive(:load).with('KIOTVIET_WEBHOOK_SECRET', nil).and_return('secret_token')
  end

  describe 'POST /webhooks/kiotviet' do
    let(:valid_headers) { { 'X-Webhook-Secret' => 'secret_token' } }
    let(:invalid_headers) { { 'X-Webhook-Secret' => 'wrong_token' } }

    context 'with invalid token' do
      it 'returns unauthorized' do
        post webhooks_kiotviet_url, headers: invalid_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with missing token' do
      it 'returns unauthorized' do
        post webhooks_kiotviet_url, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid token' do
      it 'enqueues WebhookSyncJob for order events' do
        payload = {
          'Notifications' => [
            {
              'Action' => 'order.updated',
              'Data' => [
                { 'Id' => 12_345 }
              ]
            }
          ]
        }

        expect(ConversationOrders::WebhookSyncJob).to receive(:perform_later).with(external_order_id: '12345', platform: 'kiotviet')

        post webhooks_kiotviet_url, params: payload, headers: valid_headers, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns ok without enqueuing job if order ID is missing' do
        payload = {
          'Notifications' => [
            {
              'Action' => 'order.updated',
              'Data' => [
                { 'OtherField' => 'value' }
              ]
            }
          ]
        }

        expect(ConversationOrders::WebhookSyncJob).not_to receive(:perform_later)

        post webhooks_kiotviet_url, params: payload, headers: valid_headers, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
