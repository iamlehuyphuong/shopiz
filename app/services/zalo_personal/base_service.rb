class ZaloPersonal::BaseService
  include ::FileTypeHelper
  include ZaloPersonal::Const

  pattr_initialize [:inbox!, :params!]

  def perform
    return if VALID_TYPE.exclude?(params[:type])
    if exist_message = find_exist_message
      return update_timestamp(exist_message)
    end

    set_contact
    update_contact
    first_message_processing if first_message?
    set_conversation
    build_message
    @message.save!
  rescue ArgumentError
    Rails.logger.error "Unexpected format for params[:data][:content]: #{params[:data][:content]}"
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def first_message?
    @contact.messages.empty?
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
    zalo_user? ? user_contact_attributes : group_contact_attributes
  end

  def user_contact_attributes
    user_info = get_user_info
    return {} unless user_info

    attributes = { name: user_info['displayName'] }
    if user_info['phoneNumber'].present?
      phone = user_info['phoneNumber']
      phone = "+#{phone}" unless phone.start_with?('+')
      attributes.merge!(phone_number: phone)
    end

    attributes
  end

  def group_contact_attributes
    group_info = get_group_info
    return {} unless group_info

    { name: group_info['name'] }
  end

  def set_conversation
    lock_key = format(Redis::RedisKeys::CONVERSATION_SOURCE_KEY, id: params[:threadId])

    wait_if_locked(lock_key)
    Redis::Alfred.setex(lock_key, true, 1.minutes)

    begin
      @conversation = active_conversation || create_conversation

      update_addition_attributes if @conversation
    ensure
      ::Redis::Alfred.delete(lock_key)
    end
  end

  def active_conversation
    @contact_inbox.conversations.where.not(status: :resolved).last
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
        type: zalo_user? ? 0 : 1,
        group: zalo_user? ? nil : group_addition_attributes
      }
    }
  end

  def update_addition_attributes
    additional_attributes = @conversation.additional_attributes || {}
    additional_attributes[:type] = zalo_user? ? 0 : 1
    additional_attributes[:group] = zalo_user? ? nil : group_addition_attributes
    @conversation.update!(additional_attributes: additional_attributes)
  end

  def group_addition_attributes
    group_info = get_group_info
    return {} unless group_info

    group_info.slice('name', 'avt')
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

  def first_message_processing
    return if @contact.name != params[:data][:dName]

    channel.send_message_cs(request_user_info_body)
  end

  def request_user_info_body
    {
      recipient: {
        user_id: params[:data][:uidFrom]
      },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'request_user_info',
            elements: [{
              title: 'Shopiz cảm ơn bạn đã liên hệ',
              subtitle: 'Nhấp vào đây để cung cấp thông tin của bạn',
              image_url: 'https://noventiq.si/uploads/resizer/images/2b68b5/ed7a86/d2b6d2/origin-mode1-760x362.jpg'
            }]
          }
        }
      }
    }
  end

  def update_contact
    zalo_user? ? update_user_info : update_group_info
  end

  def update_user_info
    user_info = get_user_info
    return unless user_info

    update_params = { name: user_info['displayName'] }
    if user_info['phoneNumber'].present?
      phone = user_info['phoneNumber']
      phone = "+#{phone}" unless phone.start_with?('+')
      update_params.merge!(phone_number: phone)
    end
    @contact.update!(update_params)

    ::Avatar::AvatarFromUrlJob.perform_later(@contact, user_info['avatar'])
  end

  def update_group_info
    group_info = get_group_info
    return unless group_info

    @contact.update!(name: group_info['name'])
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, group_info['fullAvt'])
  end

  def get_user_info(user_id = nil)
    return @user_info if defined?(@user_info)

    user_id ||= target_user
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      :body => { :userId => user_id, :ownId => channel.oa_access_token }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )
    return @user_info = nil if response['error']

    @user_info = response['data']['changed_profiles'][user_id]
  end

  def get_group_info
    return @group_info if defined?(@group_info)

    group_id = params[:data][:idTo]
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getGroupInfo",
      :body => { :groupId => group_id, :ownId => channel.oa_access_token }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )
    return @group_info = nil if response['error']

    @group_info = response['data']['gridInfoMap'][group_id]
  end

  def message_params
    additional_attributes = {
      type: zalo_user? ? 0 : 1,
      msgId: params[:data][:msgId]
    }
    unless zalo_user?
      sender_info = get_user_info(params[:data][:uidFrom])
      additional_attributes.merge!(sender: sender_info['displayName'], thumbnail: sender_info['avatar']) if sender_info
    end

    {
      content: params[:data][:content],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: incoming_message? ? @contact : nil,
      additional_attributes: additional_attributes,
      source_id: params[:data][:msgId],
      created_at: created_time,
    }
  end

  def incoming_message?
    message_type == :incoming
  end

  def update_timestamp(message)
    message.update_columns(created_at: created_time)
  end

  def created_time
    Time.at(params[:data][:ts].to_i / 1000)
  end

  def find_exist_message
    inbox.messages.find_by("source_id = :source_id OR additional_attributes ->> 'attachment_msg_id' = :source_id",
      source_id: params.dig(:data, :msgId).to_s)
  end
end
