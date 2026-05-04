# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::OrderActivityMessageService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:user) { create(:user, account: account, name: 'Agent Minh') }
  let(:order) { create(:conversation_order, :pushed, account: account, conversation: conversation) }

  describe '#perform' do
    it 'enqueues ActivityMessageJob for :created action' do
      service = described_class.new(conversation: conversation, order: order, action_type: :created, user: user)

      expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(conversation, hash_including(:content))
      service.perform
    end

    it 'enqueues ActivityMessageJob for :pushed action' do
      service = described_class.new(conversation: conversation, order: order, action_type: :pushed, user: user)

      expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(conversation, hash_including(:content))
      service.perform
    end

    it 'enqueues ActivityMessageJob for :synced action' do
      service = described_class.new(conversation: conversation, order: order, action_type: :synced, user: user)

      expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(conversation, hash_including(:content))
      service.perform
    end

    it 'enqueues ActivityMessageJob for :cancelled action' do
      service = described_class.new(conversation: conversation, order: order, action_type: :cancelled, user: user)

      expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(conversation, hash_including(:content))
      service.perform
    end

    it 'enqueues ActivityMessageJob for :deleted action' do
      service = described_class.new(conversation: conversation, order: order, action_type: :deleted, user: user)

      expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(conversation, hash_including(:content))
      service.perform
    end

    it 'does nothing when conversation is nil' do
      service = described_class.new(conversation: nil, order: order, action_type: :created, user: user)

      expect(Conversations::ActivityMessageJob).not_to receive(:perform_later)
      service.perform
    end

    it 'does nothing when order is nil' do
      service = described_class.new(conversation: conversation, order: nil, action_type: :created, user: user)

      expect(Conversations::ActivityMessageJob).not_to receive(:perform_later)
      service.perform
    end

    it 'uses "System" as user_name when user is nil' do
      service = described_class.new(conversation: conversation, order: order, action_type: :created, user: nil)

      expect(Conversations::ActivityMessageJob).to receive(:perform_later) do |_conv, params|
        expect(params[:content]).to include('System')
      end
      service.perform
    end
  end
end
