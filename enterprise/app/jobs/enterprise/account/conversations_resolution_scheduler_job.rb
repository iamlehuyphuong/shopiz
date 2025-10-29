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
      next if inbox.email? || account.auto_resolve_after.to_i <= 0

      Captain::InboxPendingConversationsResolutionJob.perform_later(
        inbox, account.auto_resolve_after
      )
    end
  end
end
