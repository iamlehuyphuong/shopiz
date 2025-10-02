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
    price = product.table[:prices].first
    price_amount = price["price_amount"]
    order = Vnpay::OrderInfo.new(
      amount: price_amount * 250,
      created_at: Time.now,
      order_type: 'other',
      payment_ref: 'SHOPIZ-' + customer_id.to_s + '-' + Time.now.to_i.to_s,
      description: "Thanh toán cho Shopiz - Gói #{product[:name]} - Tham số: product_id=#{product[:id]}||price_id=#{price['id']}||customer_id=#{customer_id}",
    )
    #print "Vnpay order: #{order.inspect}"
    payment_url = Vnpay::Url.new(order, '127.0.0.1', return_url)
    print "Vnpay payment_url: #{payment_url.generate}"
    payment_url.generate
  end

  def create_payos_session(customer_id, product_id, product_name)
    Polar.configure do |config|
      config.access_token = ENV['POLAR_ACCESS_TOKEN']
      config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
    end
    product = Polar::Product.get(product_id)
    price = product.table[:prices].first
    price_amount = price["price_amount"]
    order_code = "#{Time.now.to_i.to_s[-10..]}#{customer_id}".to_i
    description = "TT SHOPIZ #{product_name} #{Enterprise::Billing::PlanMapper.get_duration(product_id)}".upcase
    return_url = ENV.fetch('FRONTEND_URL')

    res = Payos::PaymentService.new.create_order(
      amount: price_amount * 250,
      order_code: order_code,
      return_url: return_url,
      cancel_url: return_url,
      description: description
    )

    res.dig(:data, :checkoutUrl)
  rescue StandardError => e
    nil
  end
end
