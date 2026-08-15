class ZaloPersonal::BaseService
  include ::FileTypeHelper
  include ZaloPersonal::Const

  pattr_initialize [:inbox!, :params!]

  def perform
    if (exist_message = find_exist_message)
      return update_extra_info(exist_message)
    end

    @is_user = zalo_user?
    @user_info = load_user_info
    @group_info = load_group_info unless @is_user

    set_contact
    update_contact
    set_conversation
    build_message
    @message.save!

    enqueue_attachment_downloads
  rescue ArgumentError => e
    Rails.logger.error "Zalo Personal Unhandled MsgType: #{params.dig(:data, :msgType)} - Payload: #{params[:data].to_json} - Error: #{e.message}"
  end

  def enqueue_attachment_downloads
    @message.attachments.each do |attachment|
      Attachment::DownloadFromUrlJob.perform_later(attachment.id) if attachment.external_url.present? && !attachment.file.attached?
    end
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

    name = @user_info['zaloName'].presence || @user_info['displayName'].presence
    attributes = { name: name }
    if @user_info['phoneNumber'].present?
      phone = @user_info['phoneNumber']
      phone = "+#{phone}" unless phone.start_with?('+')
      attributes[:phone_number] = phone
    end

    if @user_info['avatar'].present?
      attributes[:avatar_url] = @user_info['avatar']
      attributes[:additional_attributes] = { 'avatar_url' => @user_info['avatar'] }
    end

    attributes
  end

  def group_contact_attributes
    return {} if @group_info.blank?

    attributes = { name: @group_info['name'] }
    if @group_info['fullAvt'].present?
      attributes[:avatar_url] = @group_info['fullAvt']
      attributes[:additional_attributes] = { 'avatar_url' => @group_info['fullAvt'] }
    end

    attributes
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
    attrs = { group_id: params[:idTo] }
    return attrs if @group_info.blank?

    @group_info.slice('name', 'avt', 'desc', 'description', 'link', 'groupLink').merge(attrs)
  end

  def build_message
    if params[:msgType].to_s.start_with?('chat.')
      case params[:msgType]
      when 'chat.sticker'
        process_sticker_message
      when 'chat.photo', 'chat.image', 'chat.gif'
        process_media_message
      when 'chat.voice', 'chat.audio', 'chat.video', 'chat.file'
        process_file_message
      else
        process_text_message
      end
    elsif params[:_stickerDetail]
      process_sticker_message
    else
      case params[:type]
      when 1
        # If content has msgType == 'chat.video', it's a video wrapped in type 1
        inner_msg_type = (params.dig(:content, 'msgType') || params.dig(:content, :msgType)).to_s
        if inner_msg_type == 'chat.video' || video_url?(params.dig(:content, :href) || params.dig(:content, 'href'))
          process_file_message
        else
          process_text_message
        end
      when 2
        process_media_message
      when 3, 4, 5 # Nếu có audio, video, file
        process_file_message
      else
        process_text_message # fallback default
      end
    end

    assign_quote_message
  end

  def assign_quote_message
    return if params.dig(:quote, :globalMsgId).blank?

    content_attributes = @message.content_attributes || {}
    content_attributes[:in_reply_to_external_id] = params[:quote][:globalMsgId]
    @message.content_attributes = content_attributes
  end

  def process_text_message
    content = if params[:content].is_a?(Hash) || params[:content].is_a?(ActionController::Parameters)
                hash_content = params[:content]

                # Check if it's a Zalo call bubble
                if hash_content['action'] == 'recommened.calltime' || hash_content[:action] == 'recommened.calltime' || hash_content['title'] == 'sendBubbleMessage' || hash_content[:title] == 'sendBubbleMessage'
                  return process_zalo_call_message(hash_content)
                end

                image_url = hash_content['thumb'] || hash_content[:thumb] || hash_content['image'] || hash_content[:image]
                if image_url.present?
                  params[:attachments] ||= []
                  params[:attachments] << {
                    type: 'image',
                    payload: { url: image_url, name: 'thumb' }
                  }
                end
                extract_text_from_hash(hash_content)
              else
                params[:content].to_s
              end

    params[:content] = content.gsub(ICON_REGEX, ICON_MAPPING) if content.present?
    @message = @conversation.messages.build(message_params)
    attach_media
  end

  def process_zalo_call_message(hash_content)
    call_params_str = hash_content['params'] || hash_content[:params]
    call_params = call_params_str.present? ? JSON.parse(call_params_str) : {}
    duration = call_params['duration'].to_i

    @message = @conversation.messages.build(message_params.merge(
                                              content_type: 'voice_call',
                                              content: hash_content['description'] || hash_content[:description] || 'Cuộc gọi',
                                              content_attributes: {
                                                data: {
                                                  status: duration.positive? ? 'completed' : 'no-answer',
                                                  callType: call_params['calltype'] == 1 ? 'video' : 'audio',
                                                  duration: duration
                                                }
                                              }
                                            ))
    attach_media
  end

  def extract_text_from_hash(content_hash, is_media: false)
    title = content_hash['title'] || content_hash[:title]
    desc = content_hash['description'] || content_hash[:description]
    href = is_media ? nil : (content_hash['href'] || content_hash[:href])

    [title, desc, href].compact_blank.join("\n")
  end

  def process_media_message
    url = params[:url] || params.dig(:file,
                                     :url) || params.dig(:content,
                                                         :href) || params.dig(:content,
                                                                              'href') || params.dig(:content, :thumb) || params.dig(:content, 'thumb')

    if params[:content].is_a?(Hash) || params[:content].is_a?(ActionController::Parameters)
      params[:content] = extract_text_from_hash(params[:content], is_media: true)
    end

    params[:content] = nil if params[:content] == url

    @message = @conversation.messages.build(message_params)
    media_type = video_url?(url) ? 'video' : 'image'
    @media = {
      type: media_type,
      payload: {
        url: url,
        name: params[:msgId] || media_type
      }
    }
    params[:attachments] ||= []
    params[:attachments] << @media
    attach_media
  end

  def process_file_message
    extracted_url = nil
    if params[:content].is_a?(Hash) || params[:content].is_a?(ActionController::Parameters)
      extracted_url = params.dig(:content, :href) || params.dig(:content, 'href')
      params[:content] = extract_text_from_hash(params[:content], is_media: true)
    end

    url = extracted_url || params[:url] || params.dig(:file, :url)
    url ||= params[:content] if params[:content].is_a?(String) && params[:content].match?(%r{^https?://})

    # Clear text content if it's just the video URL
    if params[:content] == url || (params[:content].to_s.strip.match?(%r{^https?://}) && url.to_s.include?(params[:content].to_s.strip))
      params[:content] = nil
    end

    @message = @conversation.messages.build(message_params)
    type = case params[:msgType]
           when 'chat.voice', 'chat.audio' then 'audio'
           when 'chat.video' then 'video'
           else
             case params[:type]
             when 3 then 'audio'
             when 4 then 'video'
             else
               video_url?(url) ? 'video' : 'file'
             end
           end

    @media = {
      type: type,
      payload: {
        url: url,
        name: params[:msgId] || 'file'
      }
    }
    params[:attachments] ||= []
    params[:attachments] << @media
    attach_media
  end

  def process_sticker_message
    params[:content] = '[Sticker]'
    @message = @conversation.messages.build(message_params)
    @media = {
      type: 'sticker',
      payload: {
        url: params.dig(:_stickerDetail, :stickerUrl),
        name: params.dig(:_stickerDetail, :id)
      }
    }
    params[:attachments] ||= []
    params[:attachments] << @media
    attach_media
  end

  def attach_media
    return if params[:attachments].blank?

    params[:attachments].each do |media|
      attach_file(media)
    end
  end

  def attach_file(media)
    external_url = media&.dig(:payload, :url)
    return unless external_url

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(media),
      external_url: external_url
    )

    # Enqueue the background job to download and attach the file later
    # if the message is saved successfully.
    # We need to perform this job after the message and attachment are saved,
    # which happens when the message is eventually saved by the service.
    # But wait, @message.attachments.new doesn't save the attachment yet.
    # We will trigger the download job from a callback in the Attachment model or just handle it here?
    # For simplicity, we can do it after the message is saved in `perform` method.

    @message.content_type = 'sticker' if media[:type] == 'sticker'
  end

  def file_content_type(media)
    return :sticker if media[:type] == 'sticker'
    return :image if %w[image gif].include?(media[:type])
    return :audio if media[:type] == 'audio'
    return :video if media[:type] == 'video'

    file_type(media[:payload][:type])
  end

  def update_contact
    @is_user ? update_user_info : update_group_info
  end

  def update_user_info
    return if @user_info.blank?

    attributes = @contact.additional_attributes || {}
    attributes[:description] = @user_info['status']
    attributes['avatar_url'] = @user_info['avatar'] if @user_info['avatar'].present?

    unless @user_info['isFr'].nil?
      inbox_ids = Array(attributes['zalo_friend_inbox_ids'] || attributes[:zalo_friend_inbox_ids] || [])
      if [1, true, '1'].include?(@user_info['isFr'])
        inbox_ids |= [@inbox.id]
      else
        inbox_ids -= [@inbox.id]
      end
      attributes[:zalo_friend_inbox_ids] = inbox_ids.uniq.compact
    end

    name = @user_info['zaloName'].presence || @user_info['displayName'].presence
    update_params = {
      name: name,
      gender_id: @user_info['gender'],
      additional_attributes: attributes,
      birthday: begin
        Date.parse(@user_info['sdob'])
      rescue StandardError
        nil
      end
    }

    if @user_info['phoneNumber'].present?
      phone = @user_info['phoneNumber']
      phone = "+#{phone}" unless phone.start_with?('+')
      update_params[:phone_number] = phone
    end
    @contact.update!(update_params)

    ::Avatar::AvatarFromUrlJob.perform_later(@contact, @user_info['avatar']) if @user_info['avatar'].present?
  end

  def update_group_info
    return if @group_info.blank?

    attributes = @contact.additional_attributes || {}
    attributes['avatar_url'] = @group_info['fullAvt'] if @group_info['fullAvt'].present?
    attributes[:description] = @group_info['desc'] if @group_info['desc'].present?

    @contact.update!(name: @group_info['name'], additional_attributes: attributes)
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, @group_info['fullAvt']) if @group_info['fullAvt'].present?
  end

  def load_user_info
    user_id = target_user
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      :body => { :userId => [user_id.to_s], :ownId => channel.oa_id }.to_json,
      :headers => ZaloPersonal::ApiHelper.request_headers
    )
    return {} if response['error'].present? && response['error'].to_s != '0'

    data = response['data'] || {}
    profiles = (data['changed_profiles'] || {}).merge(data['unchanged_profiles'] || {})
    profiles[user_id.to_s] || {}
  rescue StandardError
    {}
  end

  def load_group_info
    group_id = params[:idTo]
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getGroupInfo",
      :body => { :groupId => group_id, :ownId => channel.oa_id }.to_json,
      :headers => ZaloPersonal::ApiHelper.request_headers
    )
    return {} if response['error'].present? && response['error'].to_s != '0'

    response.dig('data', 'gridInfoMap', group_id)
  rescue StandardError
    {}
  end

  def message_params
    sender = if incoming_message?
               @is_user ? @contact : find_or_create_sender
             end

    additional_attributes = {
      type: @is_user ? 0 : 1,
      msgId: params[:msgId],
      cliMsgId: params[:cliMsgId],
      user_id: params[:uidFrom],
      sender_id: sender&.id,
      conversation_contact_id: @conversation.contact.id,
      msgType: params[:type]
    }

    content_attributes = {}
    content_attributes[:external_echo] = true unless incoming_message?

    {
      content: params[:content],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: sender,
      content_attributes: content_attributes,
      additional_attributes: additional_attributes,
      source_id: params[:msgId],
      status: :delivered
    }
  end

  def find_or_create_sender
    contact = if @user_info['phoneNumber'].present?
                contact_from_phone_number
              else
                contact_from_source_id
              end

    if @user_info['avatar'].present?
      ::Avatar::AvatarFromUrlJob.perform_later(contact, @user_info['avatar'])

      attrs = contact.additional_attributes || {}
      if attrs['avatar_url'] != @user_info['avatar']
        attrs['avatar_url'] = @user_info['avatar']
        contact.update(additional_attributes: attrs)
      end
    end

    contact
  end

  def contact_from_phone_number
    phone_number = @user_info['phoneNumber']
    phone_number = "+#{phone_number}" unless phone_number.start_with?('+')

    name = @user_info['zaloName'].presence || @user_info['displayName'].presence
    account.contacts.find_or_create_by!(phone_number: phone_number) do |contact|
      contact.name = name

      attrs = { source_id: params[:uidFrom] }
      attrs['avatar_url'] = @user_info['avatar'] if @user_info['avatar'].present?
      contact.additional_attributes = attrs
    end
  end

  def contact_from_source_id
    name = @user_info['zaloName'].presence || @user_info['displayName'].presence
    account.contacts.where(
      "additional_attributes ->> 'source_id' = :source_id", source_id: params[:uidFrom]
    ).first_or_create do |contact|
      contact.name = name

      attrs = { source_id: params[:uidFrom] }
      attrs['avatar_url'] = @user_info['avatar'] if @user_info['avatar'].present?
      contact.additional_attributes = attrs
    end
  end

  def incoming_message?
    message_type == :incoming
  end

  def update_extra_info(message)
    attrs = message.additional_attributes || {}
    attrs[:msgId] = params[:msgId]
    attrs[:cliMsgId] = params[:cliMsgId] if params[:cliMsgId].present?
    attrs[:msgType] = params[:type]
    attrs[:user_id] = params[:uidFrom]
    attrs[:type] = params[:type]

    message.update(additional_attributes: attrs)
  end

  def find_exist_message
    inbox.messages.find_by(
      "source_id = :source_id OR additional_attributes ->> 'msgId' = :source_id OR additional_attributes ->> 'cliMsgId' = :source_id OR additional_attributes ->> 'attachment_msg_id' = :source_id",
      source_id: params[:msgId].to_s
    )
  end

  def video_url?(url)
    return true if params[:msgType] == 'chat.video' || params.dig(:content,
                                                                  'msgType') == 'chat.video' || params.dig(:content, :msgType) == 'chat.video'
    return false if url.blank?

    url.match?(/\.(mp4|mov|avi|mkv|webm)$/i) || url.include?('video-stal') || url.include?('video')
  end
end
