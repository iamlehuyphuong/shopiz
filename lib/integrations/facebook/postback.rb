# frozen_string_literal: true

class Integrations::Facebook::Postback
  def initialize(response)
    @messaging = JSON.parse(response)['messaging']
    @channel = Channel::FacebookPage.find_by(page_id: page_id)
    @inbox = @channel&.inbox
  end

  def perform
    return unless @channel

    create_message
    execute_macro
  end

  private

  def execute_macro
    return unless @inbox

    macro = @inbox.account.macros.find_by(name: macro_name)
    return unless macro

    user = @inbox.members.first
    ::Macros::ExecutionService.new(macro, @conversation, user).perform
  end

  def create_message
    init_contact_inbox
    init_converstation
    save_message
  end

  def init_contact_inbox
    @contact_inbox = @inbox.contact_inboxes.find_by(source_id: sender_id) || build_contact_inbox
  end

  def init_converstation
    @conversation = find_exist_conversation || build_converstation
  end

  def save_message
    @message = @conversation.messages.create!(message_params)
  end

  def find_exist_conversation
    @contact_inbox.conversations.find_by(
      inbox_id: @inbox.id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def build_converstation
    Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      last_activity_at: DateTime.now.utc,
      agent_last_seen_at: DateTime.now.utc
    )
  end

  def build_contact_inbox
    ContactInboxWithContactBuilder.new({
                                         source_id: sender_id,
                                         inbox: @inbox,
                                         contact_attributes: contact_params
                                       }).perform
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :incoming,
      content: message_content,
      source_id: @messaging['id'],
      sender: @contact_inbox.contact,
      created_at: DateTime.now.utc
    }
  end

  def contact_params
    begin
      result = graph.get_object(sender_id) || {}
    rescue StandardError => e
      result = {}
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end

    process_contact_params_result(result)
  end

  def process_contact_params_result(result)
    {
      name: "#{result['first_name'] || 'John'} #{result['last_name'] || 'Doe'}",
      account_id: @inbox.account_id,
      avatar_url: result['profile_pic']
    }
  end

  def page_id
    @messaging.dig('recipient', 'id')
  end

  def sender_id
    @messaging.dig('sender', 'id')
  end

  def message_content
    @messaging.dig('postback', 'title')
  end

  def macro_name
    @messaging.dig('postback', 'payload')
  end

  def graph
    @graph ||= Koala::Facebook::API.new(@channel.page_access_token)
  end
end
