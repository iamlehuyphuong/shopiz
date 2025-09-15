class ZaloPersonal::BaseService
  include ::FileTypeHelper

  ICON_MAPPING = {
    '/-strong' => '💪',
    '/-heart' => '❤️',
    ':-((' => '😭',
    ':>' => '😊',
    ':-h' => '🤗',
    ':o' => '😮',
    ':D' => '😃',
    '/-like' => '👍',
    '/-dislike' => '👎',
    '/-haha' => '😂',
    '/-wow' => '😲',
    '/-sad' => '😢',
    '/-angry' => '😠',
    '/-kiss' => '😘',
    '/-clap' => '👏',
    '/-ok' => '👌',
    '/-party' => '🥳',
    '/-star' => '⭐',
    '/-fire' => '🔥',
    '/-cry' => '😭',
    '/-love' => '😍',
    '/-thumbsup' => '👍',
    '/-thumbsdown' => '👎'
  }.freeze

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    update_contact
    first_message_processing if first_message?
    set_conversation
    build_message
    @message.save!
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
    @conversation = @contact_inbox.conversations.where.not(status: :resolved).last
    if @conversation
      update_addition_attributes
    else
      @conversation = ::Conversation.create!(conversation_params)
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
        group: zalo_user? ? nil : get_group_info
      }
    }
  end

  def update_addition_attributes
    additional_attributes = @conversation.additional_attributes || {}
    return if additional_attributes.dig(:group).present?

    additional_attributes[:type] = zalo_user? ? 0 : 1
    additional_attributes[:group] = zalo_user? ? nil : get_group_info
    @conversation.update!(additional_attributes: additional_attributes)
  end

  def build_message
    case params[:data][:msgType]
    when 'webchat'
      process_web_chat
    when 'chat.video.msg'
      process_media_message('video')
    when 'chat.photo'
      process_media_message('image')
    when 'chat.recommended'
      process_recommended
    else
      raise ArgumentError, 'Unexpected format for params[:data][:content]'
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
    @message = @conversation.messages.create!(message_params)
  end

  def process_media_message(media_type)
    @file = params[:data][:content]
    options = JSON.parse(@file[:params]) rescue {}
    params[:data][:content] = nil
    @message = @conversation.messages.create!(message_params)
    @media = {
      type: media_type,
      payload: {
        url: @file['href'],
        name: File.basename(URI.parse(@file['href']).path),
        width: options['width'] || options['video_width'],
        height: options['height'] || options['video_height'],
      }
    }
    params[:data][:attachments] ||= []
    params[:data][:attachments] << @media
    attach_media
  end

  def process_recommended
    @data_content = params[:data][:content]
    @description = JSON.parse(@data_content['description']) rescue {}
    params[:data][:content] = "#{@data_content['title']} - #{@description['phone']}"
    @message = @conversation.messages.create!(message_params)
    @avatar = {
      type: 'sticker',
      payload: {
        url: @data_content['thumb'],
        title: @data_content['title'],
        name: File.basename(URI.parse(@data_content['thumb']).path)
      }
    }
    @qr = {
      type: 'image',
      payload: {
        url: @description['qrCodeUrl'],
        title: @description['phone'],
        name: File.basename(URI.parse(@description['qrCodeUrl']).path)
      }
    }
    params[:data][:attachments] ||= []
    params[:data][:attachments] << @avatar
    params[:data][:attachments] << @qr
    attach_media
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

  def attach_media
    return if params[:data][:attachments].blank?

    params[:data][:attachments].each do |media|
      case media[:type]
      when 'link'
        @message.content = "Link: #{media[:payload][:url]}"
      when 'location'
        attach_location(media)
      else
        if media[:type] == 'file' && media[:payload][:size].to_i > 10 * 1024 * 1024
          @message.content = "File to download: #{media[:payload][:url]}"
          next
        end

        attach_file(media)
      end
    end
  end

  def attach_location(media)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :location,
      coordinates_lat: media[:payload][:coordinates][:latitude],
      coordinates_long: media[:payload][:coordinates][:longitude]
    )
  end

  def attach_file(media)
    external_url = media&.dig(:payload, :url)
    return unless external_url

    # attachment_file = Down.download(external_url)
    file_name = media[:payload][:name]
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(media),
      external_url: external_url,
      meta: {
        width: media.dig(:payload, :width),
        height: media.dig(:payload, :height),
      }
    )
    @message.content_type = 'sticker' if media[:type] == 'sticker'
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

  def get_user_info
    return @user_info if defined?(@user_info)

    user_id = target_user
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
    {
      content: params[:data][:content],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: incoming_message? ? @contact : nil,
      additional_attributes: {
        type: zalo_user? ? 0 : 1,
        msgId: params[:data][:msgId]
      },
      source_id: params[:data][:msgId]
    }
  end

  def incoming_message?
    message_type == :incoming
  end
end
