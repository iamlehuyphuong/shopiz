class Tiktok::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    update_contact_info if @contact.messages.empty?
    set_conversation
    @message = @conversation.messages.create!(message_params)
    attach_media
    @message.save!
  end

  private

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

  def update_contact_info
    # get profile sender by call API
  end

  def set_conversation
    @conversation = Conversation.find_by(
      external_source_id: source_conversation_id,
      contact_inbox_id: @contact_inbox.id
    )
    @conversation ||= if @inbox.lock_to_single_conversation
                  @contact_inbox.conversations.last
                else
                  @contact_inbox.conversations.where
                                .not(status: :resolved).last
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
      external_source_id: source_conversation_id,
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
      message_type: :incoming,
      sender: @contact,
      source_id: params[:data][:message_id]
    }
  end

  def attach_media
    case params[:data][:type]
    when "IMAGE"
      attach_file(data_content["url"], :image)
    when "VIDEO"
      if data_content[:size].to_i > 10 * 1024 * 1024
        @message.content = "File to download: #{data_content['url']}"
      else
        attach_file(data_content["url"], :video)
      end
    end
  end

  def message_content
    return if ["IMAGE", "VIDEO"].include?(params[:data][:type])

    data_content["content"]
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
