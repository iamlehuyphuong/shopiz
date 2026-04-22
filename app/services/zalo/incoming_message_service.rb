# Processes incoming messages from Zalo OA webhook
# Creates/updates contacts, conversations, and messages
class Zalo::IncomingMessageService
  include ::ZaloAttachmentHelper

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    update_contact_from_profile if @contact.messages.empty?
    set_conversation
    @message = @conversation.messages.build(message_params)

    @message.content_attributes[:in_reply_to_external_id] = params[:message][:quote_msg_id] if params[:message][:quote_msg_id]

    attach_media
    @message.content ||= I18n.t('inboxes.zalo.unsupported_message') if @message.attachments.blank?
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def client
    @client ||= channel.client
  end

  def update_contact_from_profile
    response = client.get_user_detail(params[:sender][:id])

    # Retry once if error (rare but API sometimes glitches)
    response = client.get_user_detail(params[:sender][:id]) unless response['error']&.zero?
    return unless response['error']&.zero?

    data = response['data']
    update_contact_basic_info(data)
    update_contact_shared_info(data['shared_info']) if data['shared_info'].present?
    avatar_url = data.dig('avatars', '240') || data['avatar']
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, avatar_url) if avatar_url.present?
  end

  def update_contact_basic_info(data)
    @contact.update!(name: data['display_name']) if data['display_name'].present?
    @contact.additional_attributes['zalo_user_id'] = data['user_id']
    @contact.additional_attributes['zalo_user_id_by_app'] = data['user_id_by_app']
    @contact.additional_attributes['zalo_is_follower'] = data['user_is_follower']
    @contact.additional_attributes['zalo_last_interaction'] = data['user_last_interaction_date']
    @contact.save!
  end

  def update_contact_shared_info(shared_info)
    # Zalo only provides these fields when user has explicitly shared them
    if shared_info['phone'].present?
      phone = shared_info['phone']
      phone = "+84#{phone[1..]}" if phone.start_with?('0')
      @contact.phone_number = phone if @contact.phone_number.blank?
    end

    if shared_info['address'].present?
      @contact.location = shared_info['address']
      @contact.additional_attributes['city'] = shared_info['city'] if shared_info['city'].present?
    end

    @contact.additional_attributes['zalo_name'] = shared_info['name'] if shared_info['name'].present?
    @contact.save!
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:sender][:id],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def message_params
    {
      content: params[:message][:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:message][:msg_id]
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved)
                                    .order(updated_at: :asc).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: params[:sender][:id]
    }
  end
end
