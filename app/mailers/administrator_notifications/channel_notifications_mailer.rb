class AdministratorNotifications::ChannelNotificationsMailer < AdministratorNotifications::BaseMailer
  def facebook_disconnect(inbox)
    subject = 'Your Facebook page connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def instagram_disconnect(inbox)
    subject = 'Your Instagram connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def tiktok_disconnect(inbox)
    subject = 'Your TikTok connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def whatsapp_disconnect(inbox)
    subject = 'Your Whatsapp connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def zalo_personal_disconnect(inbox)
    subject = 'Your Zalo Personal connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end
end
