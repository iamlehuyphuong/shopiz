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
    account = Account.find_by(id: customer_id)
    item = SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
    return nil if item.blank? || account.blank?

    amount_to_pay = item.price_amount.to_i

    if item.is_a?(SubscriptionPlan)
      sub = account.active_subscription
      current_plan = nil
      current_ends_at = nil

      if sub
        current_plan = sub.subscription_plan
        current_ends_at = sub.ends_at
      else
        sku = account.custom_attributes['sku']
        current_plan = SubscriptionPlan.find_by(sku: sku) if sku.present?
        current_ends_at = account.custom_attributes['subscription_ends_on']
      end

      if current_plan && current_ends_at.present?
        current_rank = ::BillingPresenter::PRODUCT_TYPES.index((current_plan.name_en || '').downcase) || -1
        target_rank = ::BillingPresenter::PRODUCT_TYPES.index((item.name_en || '').downcase) || -1

        if target_rank > current_rank
          # Upgrade: calculate unused value
          current_ends_at_time = current_ends_at.is_a?(String) ? Time.parse(current_ends_at) : current_ends_at
          if current_ends_at_time > Time.current && current_plan.duration_days.to_i > 0
            remaining_days = (current_ends_at_time - Time.current) / 1.day
            unused_value = ((current_plan.price_amount.to_f / current_plan.duration_days) * remaining_days).round
            amount_to_pay = [amount_to_pay - unused_value, 2000].max # Payos min amount requires 2000 VND
          end
        end
      end
    end

    sku = item.sku
    order_code = "#{Time.now.to_i.to_s[-10..]}#{customer_id}".to_i
    # Description max 25 chars: "TT SHOPIZ [SKU]"
    description = "TT SHOPIZ #{sku}".upcase[0..24]
    return_url = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{customer_id}/settings/billing"

    res = Payos::PaymentService.new.create_order(
      amount: amount_to_pay,
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
