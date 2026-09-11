class Enterprise::Webhooks::PayosController < ActionController::API
  def process_payload
    config = {
      'client_id' => GlobalConfig.get_value('PAYOS_CLIENT_ID').presence || ENV.fetch('PAYOS_CLIENT_ID', nil),
      'api_key' => GlobalConfig.get_value('PAYOS_API_KEY').presence || ENV.fetch('PAYOS_API_KEY', nil),
      'checksum_key' => GlobalConfig.get_value('PAYOS_CHECKSUM_KEY').presence || ENV.fetch('PAYOS_CHECKSUM_KEY', nil),
      'partner_id' => GlobalConfig.get_value('PAYOS_PARTNER_ID').presence || ENV.fetch('PAYOS_PARTNER_ID', nil)
    }
    provider = Payments::Providers::PayosProvider.new(config)
    payload = JSON.parse(request.raw_post)

    if provider.verify_webhook(payload, request.headers)
      parsed_data = provider.extract_webhook_data(payload)
      Rails.logger.info("[PayOS Webhook] Verified successfully for orderCode: #{parsed_data[:transaction_id]}")

      if parsed_data[:status] != 'success'
        head :bad_request
        return
      end

      ::Enterprise::Billing::HandlePayosEventService.new.perform(payload, parsed_data)
      head :ok
    else
      Rails.logger.error("[PayOS Webhook] Invalid signature: #{payload.dig('data', 'orderCode')}")
      head :bad_request
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("[PayOS Webhook] Processing error: #{e.class} - #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("[PayOS Webhook] Unexpected error: #{e.class} - #{e.message}")
    head :internal_server_error
  end
end
