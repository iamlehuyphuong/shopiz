class ZaloPersonal::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    if params[:_eventType] == 'reaction'
      reaction_message
    else
      seen_message
    end
  end

  private

  REACTION_MAPPING = {
    '/-heart' => '❤️',
    '/-strong' => '👍',
    ':>' => '😂',
    ':o' => '😲',
    ':-((' => '😭',
    ':-h' => '😡',
    ':-*' => '😘',
    ":')" => '😂',
    '/-shit' => '💩',
    '/-rose' => '🌹',
    '/-break' => '💔',
    '/-weak' => '👎',
    ';xx' => '😍',
    ';-/' => '😕',
    ';-)' => '😉',
    '/-ok' => '👌',
    '/-v' => '✌️',
    '/-thanks' => '🙏',
    '/-punch' => '👊',
    ':-bye' => '👋',
    ':))' => '😆'
  }.freeze

  def reaction_message
    content_hash = params[:content].is_a?(Hash) ? params[:content].with_indifferent_access : {}
    message_id = content_hash.dig(:rMsg, 0, :gMsgID) || params[:msgId]
    @message = inbox.messages.find_by("additional_attributes ->> 'msgId' = ?", message_id.to_s)
    return unless @message

    # Zalo Reaction String (e.g. "/-heart", or "" if removed)
    raw_icon = content_hash.key?(:rIcon) ? content_hash[:rIcon].to_s : params[:reactionType].to_s
    icon = REACTION_MAPPING[raw_icon] || raw_icon

    content_attributes = @message.content_attributes || {}
    reactions = Array(content_attributes['reactions'])
    
    if raw_icon.blank? || raw_icon == 'NONE'
      # Zalo sends empty string when reaction is removed
      reactions.clear
    else
      reactions << icon
    end

    content_attributes['reactions'] = reactions.reject(&:blank?).uniq
    @message.update!(content_attributes: content_attributes)
  end

  def seen_message
    message_ids = params[:message][:msg_ids]
    message_ids.each do |message_id|
      @message = inbox.messages.find_by(source_id: message_id)
      @message&.update!(status: :read)
    end
  end
end
