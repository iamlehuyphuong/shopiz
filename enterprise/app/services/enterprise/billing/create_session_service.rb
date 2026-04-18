class Enterprise::Billing::CreateSessionService
  def create_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    Stripe::BillingPortal::Session.create(
      {
        customer: customer_id,
        return_url: return_url
      }
    )
  end

  def create_payos_session(customer_id, product_id, product_type: nil)
    account = Account.find_by(id: customer_id)
    item = find_product(product_id, product_type)
    raise StandardError, 'Invalid account or product' if item.blank? || account.blank?

    amount_to_pay = item.price_amount.to_i

    if item.is_a?(SubscriptionPlan)
      amount_to_pay = calculate_upgrade_amount(account, item, amount_to_pay)
      raise StandardError, 'Downgrade not allowed' if amount_to_pay.nil?
    end

    sku = item.sku
    # Format order_code as 15 digits: 5-digit account_id + 10-digit timestamp
    # E.g. account 12 at 1713422345 => 000121713422345 => 121713422345
    order_code = format("%05d%10d", customer_id, Time.now.to_i).to_i
    description = "TT SHOPIZ #{sku}".upcase[0..24]
    return_url = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{customer_id}/settings/billing"

    res = Payos::PaymentService.new.create_order(
      amount: amount_to_pay,
      order_code: order_code,
      return_url: return_url,
      cancel_url: return_url,
      description: description
    )

    checkout_url = res.dig(:data, :checkoutUrl)

    account.billing_histories.create!(
      order_id: order_code.to_s,
      product_id: item.id.to_s,
      product_name: item.is_a?(SubscriptionPlan) ? item.name(account.locale) : item.name,
      sku: sku,
      status: :pending,
      price_amount: amount_to_pay,
      price_currency: 'VND',
      payment_method: 'payos',
      metadata: { type: item.is_a?(SubscriptionPlan) ? 'package' : 'addon' },
      description: description,
      checkout_url: checkout_url
    )

    checkout_url
  end

  def create_sepay_checkout(account_id, product_id, product_type: nil)
    account = Account.find_by(id: account_id)
    item = find_product(product_id, product_type)
    raise StandardError, 'Invalid account or product' if item.blank? || account.blank?

    amount_to_pay = item.price_amount.to_i

    if item.is_a?(SubscriptionPlan)
      amount_to_pay = calculate_upgrade_amount(account, item, amount_to_pay)
      raise StandardError, 'Downgrade not allowed' if amount_to_pay.nil?
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

    account.billing_histories.create!(
      order_id: order_id,
      product_id: item.id.to_s,
      product_name: item.is_a?(SubscriptionPlan) ? item.name(account.locale) : item.name,
      sku: sku,
      status: :pending,
      price_amount: amount_to_pay,
      price_currency: 'VND',
      payment_method: 'sepay',
      metadata: { type: item.is_a?(SubscriptionPlan) ? 'package' : 'addon' },
      description: description,
      checkout_url: result&.dig(:checkout_url)
    )

    result
  end

  def create_polar_session(account_id, product_id, product_type: nil)
    account = Account.find_by(id: account_id)
    item = find_product(product_id, product_type)
    raise StandardError, 'Invalid account or product' if item.blank? || account.blank?

    amount_to_pay_vnd = item.price_amount.to_i

    if item.is_a?(SubscriptionPlan)
      amount_to_pay_vnd = calculate_upgrade_amount(account, item, amount_to_pay_vnd)
      raise StandardError, 'Downgrade not allowed' if amount_to_pay_vnd.nil?
    end

    exchange_rate = GlobalConfig.get_value('EXCHANGE_RATE_VND_USD').presence&.to_i || 25_000
    exchange_rate = 25_000 if exchange_rate <= 0
    usd_cents = ((amount_to_pay_vnd.to_f / exchange_rate) * 100).round

    sku = item.sku
    order_id = "POLAR#{sku}A#{account_id}T#{Time.now.to_i}".upcase.gsub(/[^A-Z0-9]/, '')
    return_url = "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account_id}/settings/billing"
    generic_product_id = GlobalConfig.get_value('POLAR_GENERIC_PRODUCT_ID').presence || ENV.fetch('POLAR_GENERIC_PRODUCT_ID', '')

    raise StandardError, 'Polar generic product ID not configured' if generic_product_id.blank?

    client = Polar::Client.new
    res = client.create_checkout(
      amount_cents: usd_cents,
      product_id: generic_product_id,
      success_url: return_url,
      metadata: { order_id: order_id }
    )

    checkout_url = res.dig('url') || res['url']

    account.billing_histories.create!(
      order_id: order_id,
      product_id: item.id.to_s,
      product_name: item.is_a?(SubscriptionPlan) ? item.name(account.locale) : item.name,
      sku: sku,
      status: :pending,
      price_amount: amount_to_pay_vnd, # Internal amount stays in base currency (VND)
      price_currency: 'VND',
      payment_method: 'polar',
      metadata: { 
        type: item.is_a?(SubscriptionPlan) ? 'package' : 'addon',
        usd_cents: usd_cents,
        exchange_rate: exchange_rate
      },
      description: "TT SHOPIZ #{sku}".upcase[0..24],
      checkout_url: checkout_url
    )

    checkout_url
  end

  private

  def find_product(product_id, product_type)
    case product_type
    when 'addon'
      AddonPackage.find_by(id: product_id)
    when 'plan'
      SubscriptionPlan.find_by(id: product_id)
    else
      SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
    end
  end

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


