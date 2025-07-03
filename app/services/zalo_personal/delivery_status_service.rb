class ZaloPersonal::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    if params[:data][:msgType] == 'chat.reaction'
      reaction_message
    else
      seen_message
    end
  end

  private

  def reaction_message
    @message = inbox.messages.find_by("additional_attributes ->> 'msgId' = '?'", params[:data][:content][:rMsg][0][:gMsgID])

    icon_map = {
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
    }
    icon = params[:data][:content][:rIcon]
    icon = icon_map[icon] || icon
    content_attributes = @message.content_attributes || {}
    if content_attributes['reactions'].is_a?(Array)
      content_attributes['reactions'] += [icon]
    else
      content_attributes['reactions'] = [icon]
    end
    @message&.update!(content_attributes: content_attributes)
  end

  def seen_message
    message_ids = params[:message][:msg_ids]
    message_ids.each do |message_id|
      @message = inbox.messages.find_by(source_id: message_id)
      @message&.update!(status: :read)
    end
  end
end
