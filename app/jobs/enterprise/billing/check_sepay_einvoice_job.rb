# frozen_string_literal: true

class Enterprise::Billing::CheckSepayEinvoiceJob < ApplicationJob
  queue_as :default

  def perform(billing_history_id, tracking_code, attempt = 1)
    billing_history = BillingHistory.find_by(id: billing_history_id)
    return if billing_history.blank?

    client = Sepay::EinvoiceClient.new
    response = client.check_invoice_creation(tracking_code)

    unless response[:success]
      # API might return success: false if there is an error during creation
      mark_as_failed(billing_history, response)
      return
    end

    data = response[:data] || {}
    status = data[:status].to_s.downcase

    # If status is not provided but success is true, we assume it's successful (some APIs do this)
    status = 'success' if status.blank?

    if %w[processing pending].include?(status)
      if attempt < 10
        Enterprise::Billing::CheckSepayEinvoiceJob.set(wait: 10.seconds).perform_later(billing_history_id, tracking_code, attempt + 1)
      else
        mark_as_failed(billing_history, 'Timeout waiting for invoice creation')
      end
    elsif %w[success completed].include?(status)
      # Fetch the invoice details to get the PDF URL
      reference_code = billing_history.order_id
      invoice_response = client.get_invoice(reference_code)

      pdf_url = nil
      if invoice_response[:success]
        inv_data = invoice_response[:data] || {}
        pdf_url = inv_data[:pdf_url] || inv_data[:file_url] || inv_data[:url]
      end

      metadata = billing_history.metadata || {}
      metadata['einvoice_status'] = 'success'
      metadata['einvoice_url'] = pdf_url if pdf_url.present?

      billing_history.update!(metadata: metadata)
    else
      mark_as_failed(billing_history, response)
    end
  rescue StandardError => e
    Rails.logger.error("[SePay Check Invoice] #{e.message}")
    if attempt < 10
      Enterprise::Billing::CheckSepayEinvoiceJob.set(wait: 10.seconds).perform_later(billing_history_id, tracking_code, attempt + 1)
    else
      mark_as_failed(billing_history, e.message)
    end
  end

  private

  def mark_as_failed(billing_history, error_info)
    metadata = billing_history.metadata || {}
    metadata['einvoice_status'] = 'failed'
    metadata['einvoice_error'] = error_info.is_a?(String) ? error_info : error_info.to_json
    billing_history.update!(metadata: metadata)
  end
end
