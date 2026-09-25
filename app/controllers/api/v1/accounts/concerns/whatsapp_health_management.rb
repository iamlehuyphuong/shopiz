module Api::V1::Accounts::Concerns::WhatsappHealthManagement
  extend ActiveSupport::Concern

  included do
    skip_before_action :check_authorization, only: [:health, :register_webhook]
    before_action :check_admin_authorization?, only: [:register_webhook]
    before_action :validate_whatsapp_cloud_channel, only: [:health, :register_webhook]
  end

  def health
    health_data = Whatsapp::HealthService.new(@inbox.channel).fetch_health_status
    render json: health_data
  rescue StandardError => e
    Rails.logger.error "[INBOX HEALTH] Error fetching health data: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def register_webhook
    Whatsapp::WebhookSetupService.new(@inbox.channel).register_callback

    render json: { message: 'Webhook registered successfully' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "[INBOX WEBHOOK] Webhook registration failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def validate_whatsapp_cloud_channel
    return if @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.provider == 'whatsapp_cloud'

    render json: { error: 'Health data only available for WhatsApp Cloud API channels' }, status: :bad_request
  end

  def whatsapp_channel?
    @inbox.whatsapp?
  end
end
