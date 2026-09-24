require 'rails_helper'

describe MessageTemplates::HookExecutionService do
  context 'when there is no incoming message in conversation' do
    it 'will not call any hooks' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)
      # ensure greeting hook is enabled
      conversation.inbox.update(greeting_enabled: true)

      allow(MessageTemplates::Template::Greeting).to receive(:new)

      # described class gets called in message after commit
      create(:message, conversation: conversation, account: conversation.account, message_type: 'activity', content: 'Conversation marked resolved!!')

      expect(MessageTemplates::Template::Greeting).not_to have_received(:new)
    end
  end

  context 'when Greeting Message' do
    it 'doesnot calls ::MessageTemplates::Template::Greeting if greeting_message is empty' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)
      # ensure greeting hook is enabled
      conversation.inbox.update(greeting_enabled: true)

      allow(MessageTemplates::Template::Greeting).to receive(:new)

      # described class gets called in message after commit
      create(:message, conversation: conversation, account: conversation.account)

      expect(MessageTemplates::Template::Greeting).not_to have_received(:new)
    end
  end

  context 'when conversation has a campaign' do
    let(:campaign) { create(:campaign) }

    it 'does not call ::MessageTemplates::Template::Greeting on campaign conversations' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact, campaign: campaign)
      conversation.inbox.update(greeting_enabled: true, greeting_message: 'Hi, this is a greeting message')

      greeting_service = double
      allow(MessageTemplates::Template::Greeting).to receive(:new).and_return(greeting_service)
      allow(greeting_service).to receive(:perform).and_return(true)

      create(:message, conversation: conversation, account: conversation.account)

      expect(MessageTemplates::Template::Greeting).not_to have_received(:new)
    end

    it 'does not call ::MessageTemplates::Template::OutOfOffice on campaign conversations' do
      contact = create(:contact)
      conversation = create(:conversation, contact: contact, campaign: campaign)

      conversation.inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')
      conversation.inbox.working_hours.today.update!(closed_all_day: true)

      out_of_office_service = double
      allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
      allow(out_of_office_service).to receive(:perform).and_return(true)

      create(:message, conversation: conversation, account: conversation.account)

      expect(MessageTemplates::Template::OutOfOffice).not_to have_received(:new)
    end
  end

  context 'when it is after working hours' do
    it 'calls ::MessageTemplates::Template::OutOfOffice' do
      contact = create(:contact)
      conversation = create(:conversation, contact: contact)

      conversation.inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')
      conversation.inbox.working_hours.today.update!(closed_all_day: true)

      out_of_office_service = double

      allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
      allow(out_of_office_service).to receive(:perform).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation, account: conversation.account)

      expect(MessageTemplates::Template::OutOfOffice).to have_received(:new).with(conversation: message.conversation)
      expect(out_of_office_service).to have_received(:perform)
    end

    context 'with recent outgoing messages' do
      it 'does not call ::MessageTemplates::Template::OutOfOffice when there are recent outgoing messages' do
        contact = create(:contact)
        conversation = create(:conversation, contact: contact)

        conversation.inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')
        conversation.inbox.working_hours.today.update!(closed_all_day: true)

        create(:message, conversation: conversation, account: conversation.account, message_type: :outgoing, created_at: 2.minutes.ago)

        out_of_office_service = double
        allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
        allow(out_of_office_service).to receive(:perform).and_return(true)

        create(:message, conversation: conversation, account: conversation.account)

        expect(MessageTemplates::Template::OutOfOffice).not_to have_received(:new)
        expect(out_of_office_service).not_to have_received(:perform)
      end

      it 'ignores private note and calls ::MessageTemplates::Template::OutOfOffice' do
        contact = create(:contact)
        conversation = create(:conversation, contact: contact)

        conversation.inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')
        conversation.inbox.working_hours.today.update!(closed_all_day: true)

        create(:message, conversation: conversation, account: conversation.account, private: true, message_type: :outgoing, created_at: 2.minutes.ago)

        out_of_office_service = double
        allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
        allow(out_of_office_service).to receive(:perform).and_return(true)

        create(:message, conversation: conversation, account: conversation.account)

        expect(MessageTemplates::Template::OutOfOffice).to have_received(:new).with(conversation: conversation)
        expect(out_of_office_service).to have_received(:perform)
      end
    end

    it 'will not calls ::MessageTemplates::Template::OutOfOffice when outgoing message' do
      contact = create(:contact)
      conversation = create(:conversation, contact: contact)

      conversation.inbox.update(working_hours_enabled: true, out_of_office_message: 'We are out of office')
      conversation.inbox.working_hours.today.update!(closed_all_day: true)

      out_of_office_service = double

      allow(MessageTemplates::Template::OutOfOffice).to receive(:new).and_return(out_of_office_service)
      allow(out_of_office_service).to receive(:perform).and_return(true)

      # described class gets called in message after commit
      message = create(:message, conversation: conversation, account: conversation.account, message_type: 'outgoing')

      expect(MessageTemplates::Template::OutOfOffice).not_to have_received(:new).with(conversation: message.conversation)
      expect(out_of_office_service).not_to have_received(:perform)
    end
  end
end
