class Enterprise::Webhooks::PayosController < ActionController::API
  def process_payload
    service = Payos::PaymentService.new
    payload = params.to_unsafe_h
    payload = JSON.parse(request.raw_post)

    if payload['code'] != '00'
      head :bad_request
      return
    end

    if service.verify_callback(payload)
      Rails.logger.info("Payos webhook verified successfully: #{params.inspect}")

      ::Enterprise::Billing::HandlePayosEventService.new.perform(payload)
      head :ok
    else
      Rails.logger.error("[PayOS Webhook] Invalid signature: #{payload.inspect}")
      head :bad_request
    end
  rescue StandardError => e
    head :bad_request
  end
end
