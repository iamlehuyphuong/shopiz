# TODO: Move this into models jbuilder
# Currently the file there is used only for search endpoint.
# Everywhere else we use conversation builder in partials folder

json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assigned_entity.is_a?(AgentBot)
    json.assignee do
      json.partial! 'api/v1/models/agent_bot_slim', formats: [:json], resource: conversation.assigned_entity
    end
    json.assignee_type 'AgentBot'
  elsif conversation.assigned_entity&.account
    json.assignee do
      json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assigned_entity
    end
    json.assignee_type 'User'
  end
  if conversation.team.present?
    json.team do
      json.partial! 'api/v1/models/team', formats: [:json], resource: conversation.team
    end
  end
  json.hmac_verified conversation.contact_inbox&.hmac_verified
  json.show_load_more_history conversation.show_load_more_history
end

json.id conversation.display_id

# `messages[]` preview: MUST be the true last message of any type, because the frontend
# uses messages[0].id as the pagination cursor in setActiveChat. Using non_activity only
# would break pagination when a conversation's last message is an activity message.
_last_message = conversation.messages
                            .where(account_id: conversation.account_id)
                            .reorder(created_at: :desc)
                            .includes({ attachments: [{ file_attachment: [:blob] }] })
                            .first

# Build message event data directly WITHOUT calling push_event_data.
# push_event_data internally calls conversation_push_event_data which triggers an
# unread_incoming_messages query per message — an N+1 bomb across 25 conversations.
# The nested `conversation` data inside messages is not needed in the list context;
# `unread_count` is already a top-level field on the conversation payload.
_last_message_event_data = if _last_message
                             data = _last_message.attributes.symbolize_keys.merge(
                               created_at: _last_message.created_at.to_i,
                               message_type: _last_message.message_type_before_type_cast,
                               conversation_id: conversation.display_id
                             )
                             data[:attachments] = _last_message.attachments.map(&:push_event_data) if _last_message.attachments.present?
                             data[:can_undo] = _last_message.can_undo?
                             _last_message.merge_sender_attributes(data)
                           end
json.messages _last_message_event_data ? [_last_message_event_data] : []

json.account_id conversation.account_id
json.uuid conversation.uuid
json.additional_attributes conversation.additional_attributes
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.assignee_last_seen_at conversation.assignee_last_seen_at.to_i
json.can_reply conversation.can_reply?
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.custom_attributes conversation.custom_attributes
json.inbox_id conversation.inbox_id
json.active_bot conversation.inbox.active_bot?
json.labels conversation.cached_label_list_array
json.muted conversation.muted?
json.snoozed_until conversation.snoozed_until
json.reminder_at conversation.reminder_at
json.reminder_note conversation.reminder_note
json.reminder_remind_before conversation.reminder_remind_before
json.status conversation.status_display
json.created_at conversation.created_at.to_i
json.updated_at conversation.updated_at.to_f
json.timestamp conversation.last_activity_at.to_i
json.first_reply_created_at conversation.first_reply_created_at.to_i
json.unread_count conversation.unread_incoming_messages.count
# `last_non_activity_message`: if the last message is non-activity, reuse the already-fetched
# event data. Only run a separate query when the last message is an activity message.
_last_non_activity_event_data = if _last_message && _last_message.message_type != 'activity'
                                  _last_message_event_data
                                else
                                  _non_activity_msg = conversation.last_non_activity_message_obj
                                  if _non_activity_msg
                                    na_data = _non_activity_msg.attributes.symbolize_keys.merge(
                                      created_at: _non_activity_msg.created_at.to_i,
                                      message_type: _non_activity_msg.message_type_before_type_cast,
                                      conversation_id: conversation.display_id
                                    )
                                    if _non_activity_msg.attachments.present?
                                      na_data[:attachments] =
                                        _non_activity_msg.attachments.map(&:push_event_data)
                                    end
                                    na_data[:can_undo] = _non_activity_msg.can_undo?
                                    _non_activity_msg.merge_sender_attributes(na_data)
                                  end
                                end
json.last_non_activity_message _last_non_activity_event_data
json.last_activity_at conversation.last_activity_at.to_i
json.priority conversation.priority
json.waiting_since conversation.waiting_since.to_i.to_i
json.sla_policy_id conversation.sla_policy_id
json.partial! 'enterprise/api/v1/conversations/partials/conversation', conversation: conversation if ChatwootApp.enterprise?
