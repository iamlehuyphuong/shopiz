require 'rails_helper'

RSpec.describe ConversationOrders::SendUtilityMessageService do
  subject(:service) { described_class.new(order: order, conversation: conversation) }

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:order) { create(:conversation_order, account: account, status: 'confirmed', total_amount: 150000) }

  describe '#perform' do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

    before do
      allow(inbox).to receive(:channel_type).and_return(channel_type)
    end

    context 'when the channel is not supported' do
      let(:channel_type) { 'Channel::Widget' }

      it 'does not create a message' do
        expect { service.perform }.not_to change(Message, :count)
      end
    end

    context 'when the channel is Facebook Page' do
      let(:channel_type) { 'Channel::FacebookPage' }

      it 'creates an outgoing message without a message tag' do
        expect { service.perform }.to change(Message, :count).by(1)

        message = conversation.messages.last
        expect(message.message_type).to eq('outgoing')
        expect(message.content_attributes['message_tag']).to be_nil
        expect(message.content).to include("##{order.id}")
      end
    end

    context 'when the channel is Zalo Personal' do
      let(:channel_type) { 'Channel::ZaloPersonal' }

      it 'creates an outgoing message without a message tag' do
        expect { service.perform }.to change(Message, :count).by(1)

        message = conversation.messages.last
        expect(message.message_type).to eq('outgoing')
        expect(message.content_attributes['message_tag']).to be_nil
        expect(message.content).to include("##{order.id}")
      end
    end

    context 'when the channel is Telegram' do
      let(:channel_type) { 'Channel::Telegram' }

      it 'creates an outgoing message without a message tag' do
        expect { service.perform }.to change(Message, :count).by(1)

        message = conversation.messages.last
        expect(message.message_type).to eq('outgoing')
        expect(message.content_attributes['message_tag']).to be_nil
        expect(message.content).to include("##{order.id}")
      end
    end
  end
end
