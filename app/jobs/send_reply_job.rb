class SendReplyJob < ApplicationJob
  queue_as :high

  CHANNEL_SERVICES = {
    'Channel::Telegram' => ::Telegram::SendOnTelegramService,
    'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService,
    'Channel::Instagram' => ::Instagram::SendOnInstagramService,
    'Channel::Tiktok' => ::Tiktok::SendOnTiktokService,
    'Channel::WebWidget' => ::Messages::SendEmailNotificationService,
    'Channel::Api' => ::Messages::SendEmailNotificationService,
    'Channel::ZaloOa' => ::Zalo::SendOnZaloService,
    'Channel::ZaloPersonal' => ::ZaloPersonal::SendOnZaloService,
    'Channel::TiktokShop' => ::TiktokShop::SendOnTiktokService
  }.freeze

  def perform(message_id)
    message = Message.find(message_id)
    channel_name = message.conversation.inbox.channel.class.to_s

    return send_on_facebook_page(message) if channel_name == 'Channel::FacebookPage'

    service_class = CHANNEL_SERVICES[channel_name]
    return unless service_class

    service_class.new(message: message).perform
  end

  private

  def send_on_facebook_page(message)
    ::Facebook::SendOnFacebookService.new(message: message).perform
  end
end
