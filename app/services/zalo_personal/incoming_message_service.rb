class ZaloPersonal::IncomingMessageService
  include ::FileTypeHelper
  include ZaloPersonal::Const

  pattr_initialize [:inbox!, :params!]

  def perform
    return if VALID_TYPE.exclude?(params[:type])
    return if params.dig(:data, :subType).to_i == 1
    if exist_message = find_exist_message
      return update_timestamp(exist_message)
    end

    @is_user = zalo_user?
    @user_info = load_user_info
    @group_info = load_group_info unless @is_user

    set_contact
    update_contact
    set_conversation
    build_message
    @message.save!
  rescue StandardError
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def set_contact
    @contact_inbox = find_exist_contact_inbox || build_contact_inbox

    @contact = @contact_inbox.contact
  end

  def build_contact_inbox
    ::ContactInboxWithContactBuilder.new(
      source_id: params[:threadId],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform
  end

  def find_exist_contact_inbox
    @inbox.contact_inboxes.find_by(source_id: params[:threadId])
  end

  def contact_attributes
    @is_user ? user_contact_attributes : group_contact_attributes
  end

  def user_contact_attributes
    return {} if @user_info.blank?

    attributes = { name: @user_info['displayName'] }
    if @user_info['phoneNumber'].present?
      phone = @user_info['phoneNumber']
      phone = "+#{phone}" unless phone.start_with?('+')
      attributes[:phone_number] = phone
    end

    attributes
  end

  def group_contact_attributes
    return {} if @group_info.blank?

    { name: @group_info['name'] }
  end

  def set_conversation
    lock_key = format(Redis::RedisKeys::CONVERSATION_SOURCE_KEY, id: params[:threadId])

    wait_if_locked(lock_key)
    Redis::Alfred.setex(lock_key, true, 1.minute)

    begin
      @conversation = active_conversation || create_conversation

      update_addition_attributes if @conversation
    ensure
      ::Redis::Alfred.delete(lock_key)
    end
  end

  def active_conversation
    @contact_inbox.conversations.where(external_source_id: params[:threadId]).last
  end

  def create_conversation
    active_conversation || ::Conversation.create!(conversation_params)
  end

  def wait_if_locked(lock_key)
    while Redis::Alfred.get(lock_key)
      Rails.logger.info("[ConversationLock] waiting for #{lock_key}")
      sleep 0.5
    end
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      external_source_id: params[:threadId],
      additional_attributes: {
        type: @is_user ? 0 : 1,
        group: @is_user ? nil : group_addition_attributes
      }
    }
  end

  def update_addition_attributes
    additional_attributes = @conversation.additional_attributes || {}
    additional_attributes[:type] = @is_user ? 0 : 1
    additional_attributes[:group] = @is_user ? nil : group_addition_attributes
    @conversation.update(additional_attributes: additional_attributes)
  end

  def group_addition_attributes
    attrs = { group_id: params[:data][:idTo] }
    return attrs if @group_info.blank?

    @group_info.slice('name', 'avt').merge(attrs)
  end

  def build_message
    case params[:data][:msgType]
    when 'webchat'
      process_web_chat
    when 'chat.video.msg', 'chat.photo'
      process_media_message
    when 'chat.recommended'
      process_recommended
    when 'chat.voice', 'share.file'
      process_file_message
    when 'chat.sticker'
      process_sticker_message
    else
      raise ArgumentError
    end

    assign_quote_message
  end

  def assign_quote_message
    return if params.dig(:data, :quote, :globalMsgId).blank?

    content_attributes = @message.content_attributes || {}
    content_attributes[:in_reply_to_external_id] = params[:data][:quote][:globalMsgId]
    @message.content_attributes = content_attributes
  end

  def process_web_chat
    if params[:data][:content].is_a?(Hash)
      data_content = params[:data][:content]
      params[:data][:content] = [data_content[:title], data_content[:description]].compact.join("\n")
    end
    params[:data][:content] = ICON_MAPPING[params[:data][:content]] || params[:data][:content]
    @message = @conversation.messages.build(message_params)
  end

  def process_media_message
    data_content = params[:data][:content]
    options = begin
      JSON.parse(data_content[:params])
    rescue StandardError
      {}
    end
    params[:data][:content] = nil

    @message = @conversation.messages.build(message_params)
    @media = {
      type: FILE_TYPE_MAPPING[params[:data][:msgType]],
      payload: {
        url: data_content['href'],
        name: File.basename(URI.parse(data_content['href']).path),
        width: options['width'] || options['video_width'],
        height: options['height'] || options['video_height']
      }
    }
    params[:data][:attachments] ||= []
    params[:data][:attachments] << @media
    attach_media
  end

  def process_recommended
    data_content = params[:data][:content]
    description = begin
      JSON.parse(data_content['description'])
    rescue StandardError
      {}
    end
    params[:data][:content] = "#{data_content['title']} - #{description['phone']}"
    @message = @conversation.messages.build(message_params)
    params[:data][:attachments] ||= []

    if data_content['thumb'].present?
      params[:data][:attachments] << {
        type: 'sticker',
        payload: {
          url: data_content['thumb'],
          title: data_content['title'],
          name: File.basename(URI.parse(data_content['thumb']).path)
        }
      }
    end

    if description['qrCodeUrl']
      params[:data][:attachments] << {
        type: 'image',
        payload: {
          url: description['qrCodeUrl'],
          title: description['phone'],
          name: File.basename(URI.parse(description['qrCodeUrl']).path)
        }
      }
    end

    attach_media
  end

  def process_file_message
    data_content = params[:data][:content]
    if JSON.parse(data_content[:params])['fileSize'].to_i > 10 * 1024 * 1024
      params[:data][:content] = "File to download: #{data_content[:href]}"
      return @message = @conversation.messages.build(message_params)
    end

    params[:data][:content] = ''
    @message = @conversation.messages.build(message_params)

    attachment_file = Down.download(data_content[:href])
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: FILE_TYPE_MAPPING[params[:data][:msgType]],
      external_url: data_content['href'],
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def process_sticker_message
    params[:data][:content] = '[Sticker]'
    @message = @conversation.messages.build(message_params)
  end

  def attach_media
    return if params[:data][:attachments].blank?

    params[:data][:attachments].each do |media|
      if media[:type] == 'file' && media[:payload][:size].to_i > 10 * 1024 * 1024
        @message.content = "File to download: #{media[:payload][:url]}"
        next
      end

      attach_file(media)
    end
  end

  def attach_file(media)
    external_url = media&.dig(:payload, :url)
    return unless external_url

    attachment_file = Down.download(external_url)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(media),
      external_url: external_url,
      file: {
        io: attachment_file,
        filename: media.dig(:payload, :name),
        content_type: attachment_file.content_type
      }
    )
    @message.content_type = 'sticker' if media[:type] == 'sticker'
  end

  def file_content_type(media)
    return :image if %w[image gif sticker].include?(media[:type])
    return :audio if media[:type] == 'audio'
    return :video if media[:type] == 'video'

    file_type(media[:payload][:type])
  end

  def update_contact
    @is_user ? update_user_info : update_group_info
  end

  def update_user_info
    return if @user_info.blank?

    update_params = { name: @user_info['displayName'] }
    if @user_info['phoneNumber'].present?
      phone = @user_info['phoneNumber']
      phone = "+#{phone}" unless phone.start_with?('+')
      update_params[:phone_number] = phone
    end
    @contact.update(update_params)

    ::Avatar::AvatarFromUrlJob.perform_later(@contact, @user_info['avatar']) if @user_info['avatar'].present?
  end

  def update_group_info
    return if @group_info.blank?

    @contact.update(name: @group_info['name'])
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, @group_info['fullAvt']) if @group_info['fullAvt'].present?
  end

  def load_user_info
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      :body => { :userId => target_user, :ownId => channel.oa_access_token }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )
    return {} if response['error']

    response.dig('data', 'changed_profiles', target_user)
  rescue StandardError
    {}
  end

  def load_group_info
    group_id = params[:data][:idTo]
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getGroupInfo",
      :body => { :groupId => group_id, :ownId => channel.oa_access_token }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )
    return {} if response['error']

    response.dig('data', 'gridInfoMap', group_id)
  rescue StandardError
    {}
  end

  def message_params
    sender = @is_user ? @contact : find_or_create_sender

    attrs = {
      conversation_contact_id: @conversation.contact.id,
      type: @is_user ? 0 : 1,
      msgId: params[:data][:msgId],
      user_id: params[:data][:uidFrom],
      sender_id: sender&.id
    }

    {
      content: params[:data][:content],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: sender,
      additional_attributes: attrs,
      source_id: params[:data][:msgId],
      created_at: created_time,
      status: :delivered
    }
  end

  def find_or_create_sender
    sender = @user_info['phoneNumber'].present? ? contact_from_phone_number : contact_from_source_id
    ::Avatar::AvatarFromUrlJob.perform_later(sender, @user_info['avatar']) if @user_info['avatar'].present?

    sender
  end

  def contact_from_phone_number
    phone_number = @user_info['phoneNumber']
    phone_number = "+#{phone_number}" unless phone_number.start_with?('+')

    account.contacts.find_or_create_by!(phone_number: phone_number) do |c|
      c.name = @user_info['displayName']
      c.additional_attributes = { source_id: params[:data][:uidFrom] }
    end
  end

  def contact_from_source_id
    account.contacts.where(
      "additional_attributes ->> 'source_id' = :source_id", source_id: params[:data][:uidFrom]
    ).first_or_create do |c|
      c.name = @user_info['displayName'] || params[:data][:dName]
      c.additional_attributes = { source_id: params[:data][:uidFrom] }
    end
  end

  def update_timestamp(message)
    message.update_columns(created_at: created_time)
  end

  def created_time
    Time.zone.at(params[:data][:ts].to_i / 1000)
  end

  def find_exist_message
    inbox.messages.find_by("source_id = :source_id OR additional_attributes ->> 'attachment_msg_id' = :source_id",
                           source_id: params.dig(:data, :msgId).to_s)
  end

  def zalo_user?
    params[:type].zero?
  end

  def target_user
    params[:data][:uidFrom]
  end
end
