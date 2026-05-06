class Messages::LoadMoreHistoryService
  SERVICES = {
    'Channel::FacebookPage' => ::Facebook::LoadHistoryMessageService,
    'Channel::Instagram' => ::Instagram::LoadHistoryMessageService,
    'Channel::ZaloOa' => ::Zalo::LoadHistoryMessageService,
    'Channel::TiktokShop' => ::TiktokShop::LoadHistoryMessageService
  }.freeze

  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    service = SERVICES[@conversation.inbox.channel_type]
    return [] unless service

    message_ids = service.new(@conversation).perform
    Message.where(id: message_ids)
  end
end
