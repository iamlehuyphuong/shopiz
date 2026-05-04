# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::PeriodicOrderSyncJob do
  let!(:account) { create(:account) }
  let!(:order_needs_sync) { create(:conversation_order, :pushed, account: account, last_synced_at: 1.hour.ago) }
  let!(:order_recently_synced) { create(:conversation_order, :pushed, account: account, last_synced_at: 10.minutes.ago) }
  let!(:order_never_synced) { create(:conversation_order, :pushed, account: account, last_synced_at: nil) }
  let!(:order_delivered) { create(:conversation_order, :delivered, account: account, last_synced_at: 1.hour.ago) }
  let!(:order_cancelled) { create(:conversation_order, :cancelled, account: account, last_synced_at: 1.hour.ago) }

  describe '#perform' do
    before do
      allow(ConversationOrders::SyncService).to receive(:new).and_return(double(perform: { success: true }))
    end

    it 'syncs orders that are not terminal and last synced more than 30 mins ago' do
      expect(ConversationOrders::SyncService).to receive(:new).with(order: order_needs_sync)

      described_class.new.perform
    end

    it 'syncs orders that have never been synced (last_synced_at is nil)' do
      expect(ConversationOrders::SyncService).to receive(:new).with(order: order_never_synced)

      described_class.new.perform
    end

    it 'skips orders synced within the last 30 minutes' do
      expect(ConversationOrders::SyncService).not_to receive(:new).with(order: order_recently_synced)

      described_class.new.perform
    end

    it 'skips terminal orders (delivered, cancelled)' do
      expect(ConversationOrders::SyncService).not_to receive(:new).with(order: order_delivered)
      expect(ConversationOrders::SyncService).not_to receive(:new).with(order: order_cancelled)

      described_class.new.perform
    end

    it 'continues processing if one order sync fails' do
      failing_sync = double
      allow(failing_sync).to receive(:perform).and_raise(StandardError, 'API Error')

      allow(ConversationOrders::SyncService).to receive(:new).with(order: order_needs_sync).and_return(failing_sync)

      successful_sync = double
      allow(successful_sync).to receive(:perform).and_return({ success: true })
      allow(ConversationOrders::SyncService).to receive(:new).with(order: order_never_synced).and_return(successful_sync)

      # Should not raise error and should process the second order
      expect { described_class.new.perform }.not_to raise_error
    end
  end
end
