# frozen_string_literal: true

class Enterprise::Billing::HandlePayosEventService
  # orderCode format: last 8 digits of timestamp + 4-digit zero-padded account_id
  ACCOUNT_ID_DIGITS = 4

  def perform(payload)
    prepare_data(payload)
    return if @account.blank? || @record.blank?

    # Idempotency: skip if already processed
    reference = payload.dig('data', 'reference').to_s
    if reference.present? && @account.billing_histories.exists?(transaction_id: reference)
      Rails.logger.info("[PayOS] Skipping duplicate webhook for reference: #{reference}")
      return
    end

    ActiveRecord::Base.transaction do
      @record.is_a?(SubscriptionPlan) ? activate_plan : activate_addon
      save_billing_history(payload)
    end
  end

  private

  def prepare_data(payload)
    description = payload.dig('data', 'description').to_s
    # Description format: "TT SHOPIZ <SKU>" (set during checkout)
    sku_match = description.match(/TT SHOPIZ\s+(.+)/i)
    sku = sku_match ? sku_match[1].strip : nil

    @record = (SubscriptionPlan.find_by(sku: sku) || AddonPackage.find_by(sku: sku)) if sku.present?

    # Extract account_id from orderCode: last ACCOUNT_ID_DIGITS digits
    order_code = payload.dig('data', 'orderCode').to_s
    @customer_id = order_code.last(ACCOUNT_ID_DIGITS).to_i if order_code.length > ACCOUNT_ID_DIGITS
    @account = Account.find_by(id: @customer_id)
  end

  def activate_plan
    # Handle renewal vs upgrade: if same tier, extend from current ends_at
    sub = @account.active_subscription
    if sub && same_tier?(sub.subscription_plan, @record)
      # Renewal: extend from current end date
      current_ends_at = sub.ends_at > Time.current ? sub.ends_at : Time.current
      new_ends_at = current_ends_at + @record.duration_days.days

      sub.update!(status: :expired)
      @account.account_subscriptions.create!(
        subscription_plan: @record,
        starts_at: Time.current,
        ends_at: new_ends_at,
        status: :active
      )
      Subscriptions::ProvisioningService.new(@account).execute
      log_subscription(@record, new_ends_at)
    else
      # New plan or upgrade: use standard subscribe flow
      Subscriptions::SubscribeService.new(@account, @record).execute
    end
  end

  def activate_addon
    Addons::PurchaseService.new(@account, @record).execute
  end

  def same_tier?(current_plan, new_plan)
    return false unless current_plan&.subscription_tier_id && new_plan&.subscription_tier_id

    current_plan.subscription_tier_id == new_plan.subscription_tier_id
  end

  def log_subscription(plan, new_ends_at)
    @account.update!(
      custom_attributes: @account.custom_attributes.merge(
        'plan_name' => plan.name(@account.locale),
        'sku' => plan.sku,
        'subscription_status' => 'active',
        'subscription_ends_on' => new_ends_at.to_s
      )
    )
  end

  def save_billing_history(payload)
    data = payload['data']
    product_name = @record.is_a?(SubscriptionPlan) ? @record.name(@account.locale) : @record.name

    @account.billing_histories.create!(
      price_amount: data['amount'],
      price_currency: data['currency'] || 'vnd',
      product_name: product_name,
      sku: @record.sku,
      status: 0,
      product_id: @record.id.to_s,
      metadata: {
        type: @record.is_a?(SubscriptionPlan) ? 'package' : 'addon',
        sku: @record.sku,
        id: @record.id,
        payment_method: 'payos'
      },
      transaction_id: data['reference'],
      description: data['description'],
      transaction_date_time: data['transactionDateTime']
    )
  end
end
