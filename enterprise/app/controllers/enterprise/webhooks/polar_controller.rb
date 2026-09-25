class Enterprise::Webhooks::PolarController < ActionController::API
  def process_payload
    payload_body = request.raw_post
    headers = request.headers

    client = Polar::Client.new

    # Verify standard webhooks signature
    unless client.verify_webhook_signature?(payload_body, headers)
      Rails.logger.error('[Polar Webhook] Invalid signature')
      head :unauthorized
      return
    end

    payload_json = JSON.parse(payload_body)
    event_type = payload_json['type']

    Rails.logger.info("[Polar Webhook] Verified successfully for event: #{event_type}")

    case event_type
    when 'order.created', 'checkout.completed', 'checkout.confirmed'
      ::Enterprise::Billing::HandlePolarEventService.new.perform(payload_json)
    else
      Rails.logger.info("[Polar Webhook] Unhandled event type: #{event_type}")
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error("[Polar Webhook] JSON parse error: #{e.message}")
    head :bad_request
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("[Polar Webhook] Processing error: #{e.class} - #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("[Polar Webhook] Unexpected error: #{e.class} - #{e.message}")
    head :internal_server_error
  end
end
