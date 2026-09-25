class Webhooks::OmicallController < ActionController::API
  def events
    Omicall::WebhookProcessorService.new(webhook_params).perform

    # OmiCall expects 200 OK
    head :ok
  rescue StandardError => e
    Rails.logger.error "OmiCall Webhook Error: #{e.message}"
    head :internal_server_error
  end

  private

  def webhook_params
    params.permit(
      :state, :phone_number, :bill_sec, :answer_sec,
      :is_callbot, :recording_file, :recording_file_url,
      :direction, :transaction_id, :note, tag: []
    ).to_h
  end
end
