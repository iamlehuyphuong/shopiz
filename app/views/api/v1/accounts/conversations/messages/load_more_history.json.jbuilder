json.meta do
  json.show_load_more_history @conversation.show_load_more_history
end

json.payload do
  json.array! @messages do |message|
    json.partial! 'api/v1/models/message', message: message
  end
end
