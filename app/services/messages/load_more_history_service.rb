class Messages::LoadMoreHistoryService
  SERVICES = {
    'Channel::FacebookPage' => ::Facebook::LoadHistoryMessageService
  }.freeze

  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    service = SERVICES[@conversation.inbox.channel.class.to_s]
    return [] unless service

    message_ids = service.new(@conversation).perform
    Message.where(id: message_ids)
  end
end
