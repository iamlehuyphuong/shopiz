class Enterprise::Billing::CreateSessionService
  def create_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    Stripe::BillingPortal::Session.create(
      {
        customer: customer_id,
        return_url: return_url
      }
    )
  end

  def create_payos_session(customer_id, product_id)
    account = Account.find_by(id: customer_id)
    item = SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
    return nil if item.blank? || account.blank?

    amount_to_pay = item.price_amount.to_i

    if item.is_a?(SubscriptionPlan)
      amount_to_pay = calculate_upgrade_amount(account, item, amount_to_pay)
      return nil if amount_to_pay.nil? # Blocked downgrade
    end

    sku = item.sku
    # Safe orderCode: last 8 digits of timestamp + 4-digit zero-padded account_id
    # Max: 99999999_9999 = 999999999999 (12 digits, safely under MAX_SAFE_INTEGER)
    order_code = "#{Time.now.to_i.to_s[-8..]}#{customer_id.to_s.rjust(4, '0')}".to_i
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
  rescue Payos::Client::PaymentError => e
    Rails.logger.error("PayOS payment error for account #{customer_id}: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("PayOS session creation failed for account #{customer_id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(5)&.join("\n"))
    nil
  end

  def create_sepay_checkout(account_id, product_id)
    account = Account.find_by(id: account_id)
    item = SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
    return nil if item.blank? || account.blank?

    amount_to_pay = item.price_amount.to_i

    if item.is_a?(SubscriptionPlan)
      amount_to_pay = calculate_upgrade_amount(account, item, amount_to_pay)
      return nil if amount_to_pay.nil?
    end

    sku = item.sku
    order_id = "SHOPIZ#{sku}A#{account_id}T#{Time.now.to_i}".upcase.gsub(/[^A-Z0-9]/, '')
    description = "TT SHOPIZ #{sku}".upcase[0..24]
    return_url = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account_id}/settings/billing"

    client = Sepay::Client.new
    result = client.create_checkout(
      amount: amount_to_pay,
      order_id: order_id,
      description: description,
      return_url: return_url
    )

    result
  rescue StandardError => e
    Rails.logger.error("SePay session creation failed for account #{account_id}: #{e.class} - #{e.message}")
    nil
  end

  private

  def calculate_upgrade_amount(account, item, base_amount)
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

    return base_amount if current_plan.blank? || current_ends_at.blank?

    current_rank = ::BillingPresenter::PRODUCT_TYPES.index((current_plan.subscription_tier&.name_en || '').downcase) || -1
    target_rank = ::BillingPresenter::PRODUCT_TYPES.index((item.subscription_tier&.name_en || '').downcase) || -1

    # Block downgrade
    return nil if target_rank >= 0 && current_rank >= 0 && target_rank < current_rank

    if target_rank > current_rank
      # Upgrade: calculate unused value from current plan
      current_ends_at_time = current_ends_at.is_a?(String) ? Time.parse(current_ends_at) : current_ends_at
      if current_ends_at_time > Time.current && current_plan.duration_days.to_i > 0
        remaining_days = (current_ends_at_time - Time.current) / 1.day
        unused_value = ((current_plan.price_amount.to_f / current_plan.duration_days) * remaining_days).round
        return [base_amount - unused_value, 2000].max # Min amount 2000 VND
      end
    end

    base_amount
  end
end


