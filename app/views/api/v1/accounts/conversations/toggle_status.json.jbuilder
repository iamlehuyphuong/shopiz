json.meta do
end

json.payload do
  json.success @status
  json.conversation_id @conversation.display_id
  json.current_status @conversation.status_display
  json.snoozed_until @conversation.snoozed_until
end
