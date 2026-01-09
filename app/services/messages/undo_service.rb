class Messages::UndoService
  SERVICES = {
    'Channel::ZaloPersonal' => ::ZaloPersonal::UndoMessageService
  }.freeze

  def initialize(message)
    @message = message
  end

  def perform
    service = SERVICES[@message.inbox.channel_type]
    raise StandardError, 'Service not found' unless service

    service.new(@message).perform
  end
end
