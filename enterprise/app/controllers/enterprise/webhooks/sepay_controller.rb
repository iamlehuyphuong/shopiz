# frozen_string_literal: true

# SePay Payment Gateway Webhook (IPN - Instant Payment Notification)
# Receives payment result notifications from SePay's hosted checkout page
# Auth: X-Secret-Key header verification
class Enterprise::Webhooks::SepayController < ActionController::API
  def process_payload
    payload = JSON.parse(request.raw_post)

    config = {
      'company_code' => GlobalConfig.get_value('SEPAY_COMPANY_CODE').presence || ENV.fetch('SEPAY_COMPANY_CODE', nil),
      'secret_key' => GlobalConfig.get_value('SEPAY_SECRET_KEY').presence || ENV.fetch('SEPAY_SECRET_KEY', nil)
    }
    provider = Payments::Providers::SepayProvider.new(config)

    unless provider.verify_webhook(payload, request.headers)
      Rails.logger.error('[SePay Webhook] Invalid secret key')
      head :unauthorized
      return
    end

    parsed_data = provider.extract_webhook_data(payload)

    # Check payment status - only process successful payments
    notification_type = payload['notification_type'].to_s.upcase
    order_status = payload.dig('order', 'order_status').to_s.upcase

    # Support both SePay Checkout (ORDER_PAID/CAPTURED/PAID) and Standard Transaction Webhook (transferAmount > 0)
    is_checkout_success = notification_type == 'ORDER_PAID' || order_status == 'CAPTURED' || order_status == 'PAID'
    is_standard_success = payload['transferAmount'].to_i > 0 && payload['id'].present?

    unless is_checkout_success || is_standard_success
      Rails.logger.info("[SePay Webhook] Non-success status: #{notification_type}/#{order_status} for order #{parsed_data[:transaction_id]}")
      render json: { success: true }, status: :ok
      return
    end

    # Idempotency: check transaction reference
    transaction_ref = parsed_data[:gateway_transaction_id]
    if transaction_ref.present? && BillingHistory.exists?(transaction_id: transaction_ref)
      Rails.logger.info("[SePay Webhook] Skipping duplicate transaction: #{transaction_ref}")
      render json: { success: true }, status: :ok
      return
    end

    ::Enterprise::Billing::HandleSepayEventService.new.perform(payload, parsed_data)
    render json: { success: true }, status: :ok
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("[SePay Webhook] Processing error: #{e.class} - #{e.message}")
    render json: { success: false }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error("[SePay Webhook] Unexpected error: #{e.class} - #{e.message}")
    head :internal_server_error
  end
end
