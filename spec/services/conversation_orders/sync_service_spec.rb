# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::SyncService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when order has no external_order_id' do
      let(:order) { create(:conversation_order, account: account, conversation: conversation) }

      it 'returns error' do
        result = described_class.new(order: order).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('not pushed')
      end
    end

    context 'when order has no external_source' do
      let(:order) do
        create(:conversation_order, account: account, conversation: conversation,
                                    external_order_id: 'EXT-123', external_source: nil)
      end

      it 'returns error' do
        result = described_class.new(order: order).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('Platform not specified')
      end
    end

    context 'when platform is unsupported' do
      let(:order) do
        create(:conversation_order, account: account, conversation: conversation,
                                    external_order_id: 'EXT-123', external_source: 'unknown_platform')
      end

      it 'returns error' do
        result = described_class.new(order: order).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported platform')
      end
    end

    context 'when sync succeeds' do
      let(:order) { create(:conversation_order, :pushed, account: account, conversation: conversation) }
      let(:proxy_instance) { instance_double(ConversationOrders::KiotvietProxy) }

      before do
        allow(ConversationOrders::KiotvietProxy).to receive(:new).and_return(proxy_instance)
        allow(proxy_instance).to receive(:fetch_order).and_return({ 'status' => 'completed' })
        allow(proxy_instance).to receive(:platform_name).and_return('KiotViet')
        allow(proxy_instance).to receive(:extract_raw_status).and_return('completed')
        allow(proxy_instance).to receive(:map_status).and_return(:delivered)
        allow(proxy_instance).to receive(:extract_total).and_return(500_000)
      end

      it 'returns success' do
        result = described_class.new(order: order, user: user).perform
        expect(result[:success]).to be true
      end

      it 'updates order status' do
        described_class.new(order: order, user: user).perform
        expect(order.reload.status).to eq('delivered')
      end

      it 'updates total_amount' do
        described_class.new(order: order, user: user).perform
        expect(order.reload.total_amount.to_f).to eq(500_000.0)
      end

      it 'updates last_synced_at' do
        described_class.new(order: order, user: user).perform
        expect(order.reload.last_synced_at).to be_present
      end
    end

    context 'when proxy raises an error' do
      let(:order) { create(:conversation_order, :pushed, account: account, conversation: conversation) }

      before do
        proxy_instance = instance_double(ConversationOrders::KiotvietProxy)
        allow(ConversationOrders::KiotvietProxy).to receive(:new).and_return(proxy_instance)
        allow(proxy_instance).to receive(:fetch_order).and_raise(StandardError, 'API timeout')
      end

      it 'returns error' do
        result = described_class.new(order: order).perform
        expect(result[:success]).to be false
        expect(result[:error]).to include('API timeout')
      end
    end
  end
end
