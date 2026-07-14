json.array! @integrations do |integration|
  json.id integration.id
  json.provider integration.provider
  json.email integration.email
  json.expires_at integration.expires_at
end
