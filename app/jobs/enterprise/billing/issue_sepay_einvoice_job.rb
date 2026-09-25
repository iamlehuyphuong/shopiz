class Enterprise::Billing::IssueSepayEinvoiceJob < ApplicationJob
  queue_as :default

  def perform(billing_history_id)
    billing_history = BillingHistory.find_by(id: billing_history_id)
    return if billing_history.blank?

    account = billing_history.account
    return if account.blank?

    enabled = GlobalConfig.get_value('SEPAY_EINVOICE_ENABLED').presence || ENV.fetch('SEPAY_EINVOICE_ENABLED', false).to_s == 'true'
    return unless enabled

    client = Sepay::EinvoiceClient.new

    # 1. Create and issue invoice
    create_response = client.create_invoice(billing_history, account, is_draft: false)
    tracking_code = create_response[:tracking_code] || create_response.dig(:data, :tracking_code)

    unless tracking_code
      Rails.logger.error("[SePay eInvoice] Failed to extract tracking_code from response: #{create_response}")
      return
    end

    # Track the tracking_code in the billing history metadata
    metadata = billing_history.metadata || {}
    metadata['einvoice_tracking_code'] = tracking_code
    metadata['einvoice_status'] = 'processing'
    billing_history.update!(metadata: metadata)

    Rails.logger.info("[SePay eInvoice] Successfully requested invoice with tracking_code #{tracking_code} for billing history #{billing_history.id}")

    # Poll for creation status
    Enterprise::Billing::CheckSepayEinvoiceJob.set(wait: 5.seconds).perform_later(billing_history.id, tracking_code)
  rescue StandardError => e
    Rails.logger.error("[SePay eInvoice Job Error] #{e.class} - #{e.message}")
  end
end
