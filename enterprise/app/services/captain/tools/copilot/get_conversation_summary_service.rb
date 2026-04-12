class Captain::Tools::Copilot::GetConversationSummaryService < Captain::Tools::BaseTool
  def self.name
    'get_conversation_summary'
  end

  description 'Get a summary of conversation counts grouped by status to understand current workload'

  def execute
    conversations = Conversation.where(account_id: @assistant.account_id)

    open_count = conversations.where(status: :open).count
    pending_count = conversations.where(status: :pending).count
    resolved_count = conversations.where(status: :resolved).count
    snoozed_count = conversations.where(status: :snoozed).count
    total = open_count + pending_count + resolved_count + snoozed_count

    unassigned_count = conversations.where(status: :open, assignee_id: nil).count

    <<~RESPONSE
      Conversation Summary:
      Total: #{total}
      - Open: #{open_count} (Unassigned: #{unassigned_count})
      - Pending: #{pending_count}
      - Snoozed: #{snoozed_count}
      - Resolved: #{resolved_count}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage')
  end
end
