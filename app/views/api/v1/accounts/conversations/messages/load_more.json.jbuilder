json.payload do
  json.array! @messages do |message|
    json.partial! 'api/v1/models/message', message: message
  end
  json.is_load_all_message @is_load_all_message
end
