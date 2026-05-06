# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::PushService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when external_source is missing' do
      let(:order) { create(:conversation_order, :with_items, account: account, conversation: conversation, external_source: nil) }

      it 'returns error' do
        result = described_class.new(order: order, user: user).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('not specified')
      end
    end

    context 'when platform is unsupported' do
      let(:order) do
        create(:conversation_order, :with_items, account: account, conversation: conversation, external_source: 'lazada')
      end

      it 'returns error' do
        result = described_class.new(order: order, user: user).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported platform')
      end
    end

    context 'when push succeeds' do
      let(:order) do
        create(:conversation_order, :with_items, account: account, conversation: conversation, external_source: 'kiotviet')
      end
      let(:proxy_instance) { instance_double(ConversationOrders::KiotvietProxy) }

      before do
        allow(ConversationOrders::KiotvietProxy).to receive(:new).and_return(proxy_instance)
        allow(proxy_instance).to receive(:create_order).and_return({ 'id' => 12_345 })
        allow(proxy_instance).to receive(:extract_order_id).and_return('12345')
        allow(proxy_instance).to receive(:extract_error).and_return(nil)
      end

      it 'returns success' do
        result = described_class.new(order: order, user: user).perform
        expect(result[:success]).to be true
      end

      it 'updates external_order_id' do
        described_class.new(order: order, user: user).perform
        expect(order.reload.external_order_id).to eq('12345')
      end

      it 'sets status to confirmed' do
        described_class.new(order: order, user: user).perform
        expect(order.reload.status).to eq('confirmed')
      end
    end

    context 'when push fails' do
      let(:order) do
        create(:conversation_order, :with_items, account: account, conversation: conversation, external_source: 'kiotviet')
      end
      let(:proxy_instance) { instance_double(ConversationOrders::KiotvietProxy) }

      before do
        allow(ConversationOrders::KiotvietProxy).to receive(:new).and_return(proxy_instance)
        allow(proxy_instance).to receive(:create_order).and_return({ 'error' => 'Invalid data' })
        allow(proxy_instance).to receive(:extract_order_id).and_return(nil)
        allow(proxy_instance).to receive(:extract_error).and_return('Invalid data')
      end

      it 'returns error' do
        result = described_class.new(order: order, user: user).perform
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid data')
      end

      it 'does not change order status' do
        described_class.new(order: order, user: user).perform
        expect(order.reload.status).to eq('draft')
      end
    end

    context 'when proxy raises an exception' do
      let(:order) do
        create(:conversation_order, :with_items, account: account, conversation: conversation, external_source: 'kiotviet')
      end

      before do
        allow(ConversationOrders::KiotvietProxy).to receive(:new).and_raise(StandardError, 'Connection refused')
      end

      it 'returns error with exception message' do
        result = described_class.new(order: order, user: user).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('Connection refused')
      end
    end
  end
end
