class Enterprise::Webhooks::PayosController < ActionController::API
  def process_payload
    service = Payos::PaymentService.new
    payload = JSON.parse(request.raw_post)

    if payload['code'] != '00'
      head :bad_request
      return
    end

    if service.verify_callback(payload)
      Rails.logger.info("[PayOS Webhook] Verified successfully for orderCode: #{payload.dig('data', 'orderCode')}")

      ::Enterprise::Billing::HandlePayosEventService.new.perform(payload)
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
