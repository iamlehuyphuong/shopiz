module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super

    resolve_captain_conversations
  end

  private

  def resolve_captain_conversations
    CaptainInbox.all.includes(inbox: :account).find_each(batch_size: 100) do |captain_inbox|
      inbox = captain_inbox.inbox
      account = inbox.account
      next if inbox.email?
      next if account.auto_resolve_after.to_i <= 0
      next if account.captain_auto_resolve_disabled?

      Captain::InboxPendingConversationsResolutionJob.perform_later(inbox)
    end
  end
end
