class Captain::Tools::Copilot::ListInboxesService < Captain::Tools::BaseTool
  def self.name
    'list_inboxes'
  end

  description 'List all inboxes in the account with their channel type and status'

  def execute
    inboxes = Inbox.where(account_id: @assistant.account_id).order(:name)
    return 'No inboxes found' unless inboxes.exists?

    <<~RESPONSE
      Total inboxes: #{inboxes.count}
      #{inboxes.map { |i| format_inbox(i) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage')
  end

  private

  def format_inbox(inbox)
    <<~INBOX.strip
      Inbox: #{inbox.name} (ID: #{inbox.id})
      Channel: #{inbox.channel_type.demodulize}
      Auto-assignment: #{inbox.enable_auto_assignment}
      Greeting: #{inbox.greeting_enabled ? inbox.greeting_message.to_s.truncate(100) : 'Disabled'}
    INBOX
  end
end
