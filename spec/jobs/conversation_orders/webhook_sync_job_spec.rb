# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::WebhookSyncJob do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    let!(:order1) { create(:conversation_order, account: account, external_order_id: 'EXT-123', external_source: 'kiotviet', status: :processing) }
    let!(:order2) { create(:conversation_order, account: account, external_order_id: 'EXT-123', external_source: 'kiotviet', status: :draft) }
    let!(:order_delivered) do
      create(:conversation_order, account: account, external_order_id: 'EXT-123', external_source: 'kiotviet', status: :delivered)
    end
    let!(:order_cancelled) do
      create(:conversation_order, account: account, external_order_id: 'EXT-123', external_source: 'kiotviet', status: :cancelled)
    end

    before do
      allow(ConversationOrders::SyncService).to receive(:new).and_return(double(perform: { success: true }))
    end

    it 'finds non-terminal orders with matching external_order_id and external_source' do
      expect(ConversationOrders::SyncService).to receive(:new).with(order: order1).and_return(double(perform: { success: true }))

      # draft is considered non-terminal here though practically it might not have an external_order_id yet
      expect(ConversationOrders::SyncService).to receive(:new).with(order: order2).and_return(double(perform: { success: true }))

      described_class.new.perform(platform: 'kiotviet', external_order_id: 'EXT-123')
    end

    it 'skips orders in terminal states (delivered, cancelled)' do
      expect(ConversationOrders::SyncService).not_to receive(:new).with(order: order_delivered)
      expect(ConversationOrders::SyncService).not_to receive(:new).with(order: order_cancelled)

      described_class.new.perform(platform: 'kiotviet', external_order_id: 'EXT-123')
    end

    it 'does nothing if no matching orders found' do
      expect(ConversationOrders::SyncService).not_to receive(:new)

      described_class.new.perform(platform: 'kiotviet', external_order_id: 'EXT-999')
    end
  end
end
