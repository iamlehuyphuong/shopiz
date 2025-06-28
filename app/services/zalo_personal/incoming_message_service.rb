class ZaloPersonal::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    update_contact_from_profile
    first_message_processing if @contact.messages.empty?
    set_conversation

    if params[:data][:msgType] == 'webchat'
      if params[:data][:content].is_a?(Hash)
        data_content = params[:data][:content]
        params[:data][:content] = [data_content[:title], data_content[:description]].compact.join("\n")
      end
      @message = @conversation.messages.create!(message_params)
    elsif params[:data][:msgType] == 'chat.video.msg'
      @file = params[:data][:content]
      params[:data][:content] = ''
      @message = @conversation.messages.create!(message_params)
      @media = {
        type: 'video',
        payload: {
          url: @file['href'],
          name: File.basename(URI.parse(@file['href']).path)
        }
      }
      params[:data][:attachments] ||= []
      params[:data][:attachments] << @media
      attach_media
    elsif params[:data][:msgType] == 'chat.photo'
      @file = params[:data][:content]
      params[:data][:content] = ''
      @message = @conversation.messages.create!(message_params)
      @media = {
        type: 'image',
        payload: {
          url: @file['href'],
          name: File.basename(URI.parse(@file['href']).path)
        }
      }
      params[:data][:attachments] ||= []
      params[:data][:attachments] << @media
      attach_media
    elsif params[:data][:msgType] == 'chat.recommended'
      @data_content = params[:data][:content]
      @description = JSON.parse(@data_content['description'])
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
    else
      raise ArgumentError, 'Unexpected format for params[:data][:content]'
    end

    #@message.content_attributes[:in_reply_to_external_id] = params[:data][:quote_msg_id] if params[:data][:quote_msg_id]
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def first_message_processing
    # try to get user info from followed user first
    update_contact_from_profile
    # request user info for unfollowed user
    request_user_info if @contact.name == params[:data][:dName]
  end

  def get_profile(user_id, access_token)
    print "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo"
    HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      :body => { :userId => user_id, :ownId => access_token }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )
  end

  def get_group(group_id, access_token)
    HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getGroupInfo",
      :body => { :groupId => group_id, :ownId => access_token }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )
  end

  def request_user_info
    body = request_user_info_body
    channel.send_message_cs(body)
  end

  def request_user_info_body
    {
      recipient: {
        user_id: params[:data][:uidFrom]
      },
      # TODO: Need to personalize the below info
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

  def update_contact_from_profile
    if params[:data][:idTo] == params[:_accountId]
      uId = params[:data][:uidFrom]
      response = get_profile(uId, channel.oa_access_token)
      # print "Response from get_profile: #{response.inspect}"
      return if response['error']

      profile = response['data']['changed_profiles'][uId]
      # print "Profile:"
      # print profile.inspect
      @contact.update!(name: profile['displayName'])
      if profile['phoneNumber'].present? && profile['phoneNumber'] != ''
        phone = profile['phoneNumber']
        phone = "+#{phone}" unless phone.start_with?('+')
        @contact.update!(phone_number: phone)
      end
      ::Avatar::AvatarFromUrlJob.perform_later(@contact, profile['avatar'])
    else
      gId = params[:data][:idTo]
      response = get_group(gId, channel.oa_access_token)
      # print "Response from get_group: #{response.inspect}"
      return if response['error']

      profile = response['data']['gridInfoMap'][gId]
      # print "Group:"
      # print profile.inspect
      @contact.update!(name: profile['name'])
      ::Avatar::AvatarFromUrlJob.perform_later(@contact, profile['fullAvt'])
    end
  end

  def update_contact_from_shared_info
    @contact.update!(
      name: params[:data][:dName]
    )
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:threadId],
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
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        type: params[:data][:idTo] == params[:_accountId] ? 0 : 1
      }
    }
  end

  def message_params
    {
      content: params[:data][:content],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:threadId],
      additional_attributes: {
        type: params[:data][:idTo] == params[:_accountId] ? 0 : 1
      }
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: params[:data][:dName]
    }
  end

  def file_content_type(media)
    return :image if %w[image gif sticker].include?(media[:type])
    return :audio if media[:type] == 'audio'
    return :video if media[:type] == 'video'

    file_type(media[:payload][:type])
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
        # File size bigger than 10Mb will show as link
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
    attachment_file = Down.download(media[:payload][:url])
    file_name = media[:payload][:name] || attachment_file.original_filename
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(media),
      file: {
        io: attachment_file,
        filename: file_name,
        content_type: attachment_file.content_type
      }
    )
    @message.content_type = 'sticker' if media[:type] == 'sticker'
  end

  def attach_file_url(media)
    attachment_file = Down.download(media[:payload][:url])
    file_name = media[:payload][:name] || attachment_file.original_filename
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      fallback_title: media[:payload][:title],
      external_url: media[:payload][:url]
    )
    @message.content_type = 'sticker' if media[:type] == 'sticker'
  end
end
