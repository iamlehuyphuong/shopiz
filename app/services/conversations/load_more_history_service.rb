class Conversations::LoadMoreHistoryService
  SERVICES = {
    'Channel::FacebookPage' => ::Facebook::LoadHistoryConversationService
  }.freeze

  def initialize(inbox)
    @inbox = inbox
  end

  def perform
    service = SERVICES[@inbox.channel.class.to_s]
    return [] unless service

    conversation_ids = []
    loop do
      conversation_ids = service.new(@inbox).perform

      break if conversation_ids.any? || @inbox.reload.is_load_all_conversation
    end
    conversations = Conversation.where(id: conversation_ids).order(last_activity_at: :desc)
    [conversations, @inbox.is_load_all_conversation]
  end
end
