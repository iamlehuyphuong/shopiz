# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Conversations::Orders', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    create(:inbox_member, inbox: conversation.inbox, user: agent)
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/{conversation.display_id}/orders' do
    it 'returns all orders for the conversation' do
      order = create(:conversation_order, account: account, conversation: conversation)

      get api_v1_account_conversation_orders_url(account_id: account.id, conversation_id: conversation.display_id),
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(order.id)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/{conversation.display_id}/orders' do
    it 'creates a new order' do
      params = {
        customer_name: 'John Doe',
        customer_phone: '1234567890',
        items_attributes: [
          { product_name: 'Item 1', quantity: 1, unit_price: 100 }
        ]
      }

      post api_v1_account_conversation_orders_url(account_id: account.id, conversation_id: conversation.display_id),
           params: params,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(ConversationOrder.count).to eq(1)

      order = ConversationOrder.last
      expect(order.customer_name).to eq('John Doe')
      expect(order.items.count).to eq(1)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/{conversation.display_id}/orders/:id/push' do
    let(:order) { create(:conversation_order, account: account, conversation: conversation, external_source: 'kiotviet') }

    it 'calls PushService' do
      push_service_mock = instance_double(ConversationOrders::PushService, perform: { success: true })
      allow(ConversationOrders::PushService).to receive(:new).and_return(push_service_mock)

      post push_api_v1_account_conversation_order_url(account_id: account.id, conversation_id: conversation.display_id, id: order.id),
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/{conversation.display_id}/orders/:id/sync' do
    let(:order) { create(:conversation_order, account: account, conversation: conversation, external_source: 'kiotviet', external_order_id: '123') }

    it 'calls SyncService' do
      sync_service_mock = instance_double(ConversationOrders::SyncService, perform: { success: true })
      allow(ConversationOrders::SyncService).to receive(:new).and_return(sync_service_mock)

      post sync_api_v1_account_conversation_order_url(account_id: account.id, conversation_id: conversation.display_id, id: order.id),
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
    end
  end
end
