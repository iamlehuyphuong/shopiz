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

  def reaction_message
    @message = inbox.messages.find_by("additional_attributes ->> 'msgId' = ?", params[:msgId].to_s)
    return unless @message

    # Map reactionType to emoji if possible (1: Like, 2: Haha, 3: Tim)
    icon = case params[:reactionType].to_i
           when 1 then '👍'
           when 2 then '😂'
           when 3 then '❤️'
           else
             params[:reactionType].to_s
           end

    content_attributes = @message.content_attributes || {}
    if content_attributes['reactions'].is_a?(Array)
      content_attributes['reactions'] += [icon]
    else
      content_attributes['reactions'] = [icon]
    end
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
