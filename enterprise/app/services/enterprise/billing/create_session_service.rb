class Enterprise::Billing::CreateSessionService
  def create_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    Stripe::BillingPortal::Session.create(
      {
        customer: customer_id,
        return_url: return_url
      }
    )
  end

  def create_vnpay_session(customer_id, product_id, return_url = ENV.fetch('FRONTEND_URL'))
    Polar.configure do |config|
      config.access_token = ENV['POLAR_ACCESS_TOKEN']
      config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
      #config.webhook_secret = ENV['POLAR_WEBHOOK_SECRET']
    end
    Vnpay::Config.configure do |config|
      config.secret_key = ENV['VNPAY_SECRET_KEY']
      config.payment_url = ENV['VNPAY_PAYMENT_URL']
      config.website_code = ENV['VNPAY_WEBSITE_CODE']
    end
    product = Polar::Product.get(product_id)
    price_amount = product[:prices].first[:price_amount]
    order = Vnpay::OrderInfo.new(
      amount: price_amount.to_i * 25000,
      created_at: Time.now,
      order_type: 'other',
      payment_ref: 'SALESMAN-' + customer_id.to_s + '-' + Time.now.to_i.to_s,
      description: 'Payment for product=' + product[:name] + ' with customer_id=' + customer_id.to_s,
    )
    print order.to_json
    payment_url = Vnpay::Url.new(order, '127.0.0.1', return_url)
    payment_url.generate
  end
end
