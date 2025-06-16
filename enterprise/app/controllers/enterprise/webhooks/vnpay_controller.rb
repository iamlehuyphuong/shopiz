class Enterprise::Webhooks::VnpayController < ActionController::API
  def process_payload
    # Get the Vnpay IPN parameters
    params = request.params
    print "Vnpay webhook received events: #{params.inspect}"

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
        Vnpay::Config.configure do |config|
          config.secret_key = ENV['VNPAY_SECRET_KEY']
          config.payment_url = ENV['VNPAY_PAYMENT_URL']
          config.website_code = ENV['VNPAY_WEBSITE_CODE']
        end
        verify = Vnpay::Verify.new(params)
        if verify.verify
          # If the signature is valid, we can process the event
          Rails.logger.info("Vnpay webhook verified successfully: #{params.inspect}")
          # Here you would typically handle the event, e.g., update an order status, notify a user, etc.
          # For example, you might want to create a job to handle the event asynchronously
          event= params
          ::Enterprise::Billing::HandleVnpayEventService.new.perform(event: event)
          render json: { success: 'Success' }, status: :ok
        else
          render json: { error: 'Invalid signature' }, status: :unauthorized
          Rails.logger.error("Vnpay webhook verification failed: #{params.inspect}")
        end
      return
    # If we fail to verify the signature, then something was wrong with the request
    rescue JSON::ParserError
      # Invalid payload
      head :bad_request
      return
    end

    # We've successfully processed the event without blowing up
    head :ok
  end
end
