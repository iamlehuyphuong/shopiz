module Tiktok::MessagingHelpers
  private

  def create_contact_inbox(channel, tt_conversation_id, from, from_id, user_info = {})
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: tt_conversation_id,
      inbox: channel.inbox,
      contact_attributes: contact_attributes(from, from_id, user_info)
    ).perform

    if user_info && user_info[:avatar_url].present? && contact_inbox.contact.avatar.blank?
      Avatar::AvatarFromUrlJob.perform_later(contact_inbox.contact, user_info[:avatar_url])
    end

    contact_inbox
  end

  def contact_attributes(from, from_id, user_info = {})
    display_name = user_info[:display_name] || user_info[:nickname] if user_info

    name = if display_name.present? && from.present? && display_name != from
             "#{display_name} (#{from})"
           elsif display_name.present?
             display_name
           else
             from
           end

    {
      name: name,
      additional_attributes: contact_additional_attributes(from, from_id)
    }
  end

  def contact_additional_attributes(from, from_id)
    {
      # TODO: Remove this once we show the social_tiktok_user_name in the UI instead of the username
      username: from,
      social_profiles: { tiktok: from },
      social_tiktok_user_id: from_id,
      social_tiktok_user_name: from
    }
  end

  def find_conversation(channel, tt_conversation_id)
    contact_inbox = channel.inbox.contact_inboxes.find_by(source_id: tt_conversation_id)
    return if contact_inbox.blank?

    if channel.inbox.lock_to_single_conversation
      contact_inbox.conversations.order(created_at: :desc).first
    else
      contact_inbox.conversations.where.not(status: :resolved).order(created_at: :desc).first ||
        contact_inbox.conversations.order(created_at: :desc).first
    end
  end

  def create_conversation(channel, contact_inbox, tt_conversation_id)
    ::Conversation.create!(conversation_params(channel, contact_inbox, tt_conversation_id))
  end

  def conversation_params(channel, contact_inbox, tt_conversation_id)
    {
      account_id: channel.inbox.account_id,
      inbox_id: channel.inbox.id,
      contact_id: contact_inbox.contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: conversation_additional_attributes(tt_conversation_id)
    }
  end

  def conversation_additional_attributes(tt_conversation_id)
    {
      conversation_id: tt_conversation_id
    }
  end

  def find_message(tt_conversation_id, tt_message_id)
    message = Message.find_by(source_id: tt_message_id)
    message_conversation_id = message&.conversation&.[](:additional_attributes)&.[]('conversation_id')
    return if message_conversation_id != tt_conversation_id

    message
  end

  def fetch_attachment(channel, tt_conversation_id, tt_message_id, tt_image_media_id)
    file_download_url = tiktok_client(channel).file_download_url(tt_conversation_id, tt_message_id, tt_image_media_id)
    Down.download(file_download_url, headers: { 'x-user' => channel.validated_access_token })
  end

  def tiktok_client(channel)
    Tiktok::Client.new(business_id: channel.business_id,  access_token: channel.validated_access_token)
  end
end
