# frozen_string_literal: true

# SePay Payment Gateway Webhook (IPN - Instant Payment Notification)
# Receives payment result notifications from SePay's hosted checkout page
# Auth: X-Secret-Key header verification
class Enterprise::Webhooks::SepayController < ActionController::API
  def process_payload
    payload = JSON.parse(request.raw_post)

    unless verify_secret_key
      Rails.logger.error('[SePay Webhook] Invalid secret key')
      head :unauthorized
      return
    end

    # Check payment status - only process successful payments
    notification_type = payload['notification_type'].to_s.upcase
    order_status = payload.dig('order', 'order_status').to_s.upcase
    unless notification_type == 'ORDER_PAID' || order_status == 'CAPTURED' || order_status == 'PAID'
      Rails.logger.info("[SePay Webhook] Non-success status: #{notification_type}/#{order_status} for order #{payload.dig('order', 'order_invoice_number')}")
      render json: { success: true }, status: :ok
      return
    end

    # Idempotency: check transaction reference
    transaction_ref = payload.dig('transaction', 'transaction_id').to_s.presence || payload.dig('transaction', 'id').to_s
    if transaction_ref.present? && BillingHistory.exists?(transaction_id: transaction_ref)
      Rails.logger.info("[SePay Webhook] Skipping duplicate transaction: #{transaction_ref}")
      render json: { success: true }, status: :ok
      return
    end

    ::Enterprise::Billing::HandleSepayEventService.new.perform(payload)
    render json: { success: true }, status: :ok
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("[SePay Webhook] Processing error: #{e.class} - #{e.message}")
    render json: { success: false }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error("[SePay Webhook] Unexpected error: #{e.class} - #{e.message}")
    head :internal_server_error
  end

  private

  def verify_secret_key
    expected = GlobalConfig.get_value('SEPAY_SECRET_KEY').presence || ENV.fetch('SEPAY_SECRET_KEY', nil)
    return false if expected.blank?

    provided_key = request.headers['Authorization'].to_s.gsub(/Bearer\s+|Apikey\s+/i, '').strip
    provided_key = request.headers['X-Secret-Key'].to_s.strip if provided_key.blank?
    return false if provided_key.blank?

    ActiveSupport::SecurityUtils.secure_compare(provided_key, expected)
  end
end
