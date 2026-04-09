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
    Vnpay::Config.configure do |config|
      config.secret_key = ENV['VNPAY_SECRET_KEY']
      config.payment_url = ENV['VNPAY_PAYMENT_URL']
      config.website_code = ENV['VNPAY_WEBSITE_CODE']
    end

    item = SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
    return nil if item.blank?

    order = Vnpay::OrderInfo.new(
      amount: item.price_amount.to_i,
      created_at: Time.now,
      order_type: 'other',
      payment_ref: 'SHOPIZ-' + customer_id.to_s + '-' + Time.now.to_i.to_s,
      description: "Thanh toán cho Shopiz - Gói #{item.name} - Tham số: product_id=#{item.id}||customer_id=#{customer_id}",
    )
    payment_url = Vnpay::Url.new(order, '127.0.0.1', return_url)
    payment_url.generate
  end

  def create_payos_session(customer_id, product_id)
    # Search in SubscriptionPlan first, then AddonPackage
    item = SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
    return nil if item.blank?

    sku = item.sku
    order_code = "#{Time.now.to_i.to_s[-10..]}#{customer_id}".to_i
    # Description max 25 chars: "TT SHOPIZ [SKU]"
    description = "TT SHOPIZ #{sku}".upcase[0..24]
    return_url = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{customer_id}/settings/billing"

    res = Payos::PaymentService.new.create_order(
      amount: item.price_amount.to_i,
      order_code: order_code,
      return_url: return_url,
      cancel_url: return_url,
      description: description
    )

    res.dig(:data, :checkoutUrl)
  rescue StandardError => e
    Rails.logger.error("PayOS session creation failed for account #{customer_id}: #{e.message}")
    nil
  end
end
