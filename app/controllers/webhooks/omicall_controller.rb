class Webhooks::OmicallController < ActionController::API

  def events
    # We offload the processing to a background job or service so we don't block the webhook provider
    # However, since we need to locate the conversation and create a note, we can process it here
    # or inside a job. Let's process it synchronously for now, or use a worker if it gets heavy.
    
    Omicall::WebhookProcessorService.new(params.to_unsafe_h).perform
    
    # OmiCall expects 200 OK
    head :ok
  rescue StandardError => e
    Rails.logger.error "OmiCall Webhook Error: #{e.message}"
    head :internal_server_error
  end
end
