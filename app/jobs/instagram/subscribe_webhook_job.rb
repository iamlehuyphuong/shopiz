class Instagram::SubscribeWebhookJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform(channel_id)
    channel = Channel::Instagram.find_by(id: channel_id)
    return unless channel

    api_version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
    response = HTTParty.post(
      "https://graph.instagram.com/#{api_version}/#{channel.instagram_id}/subscribed_apps",
      query: {
        subscribed_fields: 'messages,messaging_seen,message_reactions,comments',
        access_token: channel.access_token
      }
    )

    if response.success?
      Rails.logger.info "[Instagram] Successfully subscribed webhooks for IG user #{channel.instagram_id}: #{response.body}"
    else
      Rails.logger.error "[Instagram] Failed to subscribe webhooks for IG user #{channel.instagram_id}. Status: #{response.code}, Body: #{response.body}"
      raise "Failed to subscribe webhooks for IG user #{channel.instagram_id}. Status: #{response.code}"
    end
  end
end
