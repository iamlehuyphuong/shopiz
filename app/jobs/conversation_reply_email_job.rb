class ConversationReplyEmailJob < ApplicationJob
  queue_as :mailers

  def perform(conversation_id, last_queued_id)
    conversation = Conversation.find(conversation_id)
    return unless conversation.account.active?

    ConversationReplyMailer.with(account: conversation.account).reply_with_summary(conversation, last_queued_id).deliver_later

    Redis::Alfred.delete(format(::Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id))
  end
end
