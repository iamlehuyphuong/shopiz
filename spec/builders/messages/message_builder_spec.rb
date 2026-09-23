require 'rails_helper'

describe Messages::MessageBuilder do
  subject(:message_builder) { described_class.new(user, conversation, params).perform }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:inbox_member) { create(:inbox_member, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:message_for_reply) { create(:message, conversation: conversation) }
  let(:params) do
    ActionController::Parameters.new({
                                       content: 'test'
                                     })
  end

  describe '#perform' do
    it 'creates a message' do
      message = message_builder
      expect(message.content).to eq params[:content]
    end
  end

  describe '#content_attributes' do
    context 'when content_attributes is a JSON string' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: "{\"in_reply_to\":#{message_for_reply.id}}"
                                         })
      end

      it 'parses content_attributes from JSON string' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes).to include(in_reply_to: message_for_reply.id)
      end
    end

    context 'when content_attributes is a hash' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: { in_reply_to: message_for_reply.id }
                                         })
      end

      it 'uses content_attributes as provided' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes).to include(in_reply_to: message_for_reply.id)
      end
    end

    context 'when content_attributes is absent' do
      let(:params) do
        ActionController::Parameters.new({ content: 'test' })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end

    context 'when content_attributes is nil' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: nil
                                         })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end

    context 'when content_attributes is an invalid JSON string' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: 'invalid_json'
                                         })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end
  end

  describe '#perform when message_type is incoming' do
    context 'when channel is not api' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           message_type: 'incoming'
                                         })
      end

      it 'creates throws error when channel is not api' do
        expect { message_builder }.to raise_error 'Incoming messages are only allowed in Api and Voice inboxes'
      end
    end

    context 'when channel is api' do
      let(:channel_api) { create(:channel_api, account: account) }
      let(:conversation) { create(:conversation, inbox: channel_api.inbox, account: account) }
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           message_type: 'incoming'
                                         })
      end

      it 'creates message when channel is api' do
        message = message_builder
        expect(message.message_type).to eq params[:message_type]
      end
    end

    context 'when attachment messages' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')]
                                         })
      end

      it 'creates message with attachments' do
        message = message_builder
        expect(message.attachments.first.file_type).to eq 'image'
      end

      context 'when DIRECT_UPLOAD_ENABLED' do
        let(:params) do
          ActionController::Parameters.new({
                                             content: 'test',
                                             attachments: [get_blob_for('spec/assets/avatar.png', 'image/png').signed_id]
                                           })
        end

        it 'creates message with attachments' do
          message = message_builder
          expect(message.attachments.first.file_type).to eq 'image'
        end
      end
    end
  end
end
