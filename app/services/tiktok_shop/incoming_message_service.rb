class TiktokShop::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if already_processed?

    set_contact
    update_contact_info if should_update_contact?
    set_conversation
    @message = @conversation.messages.create!(message_params)
    attach_media
    @message.save!
  end

  private

  def already_processed?
    @inbox.messages.exists?(source_id: params[:data][:message_id])
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: im_user_id,
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def im_user_id
    params[:data][:sender][:im_user_id]
  end

  def contact_attributes
    {
      name: im_user_id
    }
  end

  def should_update_contact?
    @contact.name == im_user_id || @contact.avatar.blank?
  end

  def update_contact_info
    buyer = fetch_buyer_participant
    return unless buyer

    update_contact_name(buyer)
    update_contact_avatar(buyer)
  rescue StandardError => e
    Rails.logger.warn("[TiktokShop::IncomingMessageService] Failed to update contact info: #{e.message}")
  end

  def fetch_buyer_participant
    response = fetch_conversation_info
    return unless response&.dig('code')&.zero?

    find_buyer_in_participants(response)
  end

  def find_buyer_in_participants(response)
    participants = response.dig('data', 'participants') || []
    participants.find { |p| p['im_user_id'] == im_user_id } ||
      participants.find { |p| p['role'] == 'BUYER' }
  end

  def update_contact_name(buyer)
    return unless buyer['nickname'].present? && @contact.name == im_user_id

    @contact.update!(name: buyer['nickname'])
  end

  def update_contact_avatar(buyer)
    return unless buyer['avatar'].present? && @contact.avatar.blank?

    ::Avatar::AvatarFromUrlJob.perform_later(@contact, buyer['avatar'])
  end

  def fetch_conversation_info
    response = channel.client.get_conversation(source_conversation_id)
    if response['code'] == Channel::TiktokShop::INVALID_ACCESS_TOKEN_CODE
      channel.refresh_access_token
      response = channel.client.get_conversation(source_conversation_id)
    end
    response
  end

  def channel
    @channel ||= @inbox.channel
  end

  def set_conversation
    @conversation = Conversation.find_by(
      external_source_id: source_conversation_id,
      contact_inbox_id: @contact_inbox.id
    )
    @conversation ||= if @inbox.lock_to_single_conversation
                        @contact_inbox.conversations.last
                      else
                        @contact_inbox.conversations.where.not(status: :resolved).last
                      end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      external_source_id: source_conversation_id
    }
  end

  def source_conversation_id
    @source_conversation_id ||= params[:data][:conversation_id]
  end

  def message_params
    {
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: message_type == :outgoing ? nil : @contact,
      source_id: params[:data][:message_id],
      created_at: params[:data][:create_time]
    }
  end

  def message_type
    # TikTok sender roles: BUYER, SHOP_OWNER, etc.
    params.dig(:data, :sender, :role) == 'SHOP_OWNER' ? :outgoing : :incoming
  end

  def attach_media
    case params[:data][:type]
    when 'IMAGE'
      attach_file(data_content['url'], :image)
    when 'VIDEO'
      if data_content[:size].to_i > 10 * 1024 * 1024
        @message.content = "File to download: #{data_content['url']}"
      else
        attach_file(data_content['url'], :video)
      end
    end
  end

  def message_content
    return if %w[IMAGE VIDEO].include?(params[:data][:type])

    data_content['content']
  end

  def data_content
    @data_content ||= JSON.parse(params[:data][:content])
  end

  def attach_file(url, file_type)
    attachment_file = Down.download(url)
    file_name = attachment_file.original_filename
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type,
      file: {
        io: attachment_file,
        filename: file_name,
        content_type: attachment_file.content_type
      }
    )
  end
end
