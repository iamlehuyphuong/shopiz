class Enterprise::Webhooks::VnpayController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      Vnpay::Config.configure do |config|
        config.secret_key = ENV['VNPAY_SECRET_KEY']
        config.payment_url = ENV['VNPAY_PAYMENT_URL']
        config.website_code = ENV['VNPAY_WEBSITE_CODE']
      end
      order = Vnpay::OrderInfo.new(
        amount: 20_000,
        created_at: Time.now,
        order_type: 'other',
        payment_ref: 'TXN-110231261',
        description: 'This is a bill'
      )
      payment_url = Vnpay::Url.new(order, '127.0.0.1', ENV['FRONTEND_URL'] + '/vnpay/payment_complete')
      render json: { payment_url: payment_url.generate }
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
