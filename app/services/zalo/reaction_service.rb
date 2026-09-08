# Handles Zalo OA 'user_reacted_message' webhook event
# Stores the reaction data in the message's content_attributes
#
# Webhook payload:
# {
#   "event_name": "user_reacted_message",
#   "sender": { "id": "<user_id>" },
#   "recipient": { "id": "<oa_id>" },
#   "message": {
#     "msg_id": "<original_msg_id>",
#     "react_icon": "/-heart",
#     "react_type": "heart"
#   }
# }
class Zalo::ReactionService
  pattr_initialize [:inbox!, :params!]

  def perform
    message = inbox.messages.find_by(source_id: msg_id)
    return unless message

    content_attributes = message.content_attributes ? message.content_attributes.deep_dup : {}
    reactions = content_attributes['reactions'] || []

    # Remove existing reaction from same user if any
    reactions.reject! { |r| r['user_id'] == sender_id }

    # Add new reaction (unless it's a remove/undo action)
    if react_type.present?
      reactions << {
        'user_id' => sender_id,
        'type' => react_type,
        'icon' => react_icon,
        'created_at' => Time.current.iso8601
      }
    end

    content_attributes['reactions'] = reactions
    message.update!(content_attributes: content_attributes)
  end

  private

  def msg_id
    params[:message][:msg_id]
  end

  def sender_id
    params[:sender][:id]
  end

  def react_type
    params[:message][:react_type]
  end

  def react_icon
    params[:message][:react_icon]
  end
end
