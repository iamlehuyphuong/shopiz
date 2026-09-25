module ConversationReplyMailerHelper
  include ConversationReplyMailerAttachmentHelper

  def prepare_mail(cc_bcc_enabled)
    @options = {
      to: to_emails,
      from: email_from,
      reply_to: email_reply_to,
      subject: mail_subject,
      message_id: custom_message_id,
      in_reply_to: in_reply_to_email,
      references: references_header
    }

    if cc_bcc_enabled
      @options[:cc] = cc_bcc_emails[0]
      @options[:bcc] = cc_bcc_emails[1]
    end

    # Email type detection logic:
    # - email_reply: Sets @message with a single message
    # - Other actions: Set @messages with a collection of messages
    #
    # So this check implicitly determines we're handling an email_reply
    # and not one of the other email types (summary, transcript, etc.)
    process_attachments_as_files_for_email_reply if @message&.attachments.present?
    mail(@options)
  end

  private

  def email_from
    from_email_with_name
  end

  def email_reply_to
    reply_email
  end

  # Use channel email domain in case of account email domain is not set for custom message_id and in_reply_to
  def channel_email_domain
    domain = @account.try(:inbound_email_domain)
    return domain if domain.present?

    sender = ENV.fetch('MAILER_SENDER_EMAIL', 'Shopiz <accounts@shopiz.pro>')
    sender.split('@').last.delete('>')
  end
end
