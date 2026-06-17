class ZaloPersonal::CheckConnectionHealthJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Channel::ZaloPersonal.find_each do |channel|
      next if channel.reauthorization_required?

      check_channel_health(channel)
    rescue StandardError => e
      Rails.logger.error "ZaloPersonal health check failed for channel #{channel.id}: #{e.message}"
    end
  end

  private

  def check_channel_health(channel)
    response = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getUserInfo",
      body: { userId: channel.oa_id, ownId: channel.oa_id }.to_json,
      headers: ZaloPersonal::ApiHelper.request_headers,
      timeout: 10
    )

    return unless response['error'].present?

    Rails.logger.warn "ZaloPersonal channel #{channel.id} (oa_id: #{channel.oa_id}) is disconnected: #{response['error']}"
    channel.prompt_reauthorization!
  end
end
