# frozen_string_literal: true

# Handles SePay Payment Gateway webhook (IPN) events
# Parses order_invoice_number to extract SKU and account ID
# order_invoice_number format: SHOPIZ<SKU>A<ACCOUNT_ID>T<TIMESTAMP>
class Enterprise::Billing::HandleSepayEventService
  ORDER_ID_PATTERN = /\ASHOPIZ(.+)A(\d+)T\d+\z/i

  def perform(payload)
    prepare_data(payload)
    return if @account.blank? || @record.blank?

    ActiveRecord::Base.transaction do
      @record.is_a?(SubscriptionPlan) ? activate_plan : activate_addon
      save_billing_history(payload)
    end
  end

  private

  def prepare_data(payload)
    order_id = payload['order_invoice_number'].to_s.strip.upcase
    match = order_id.match(ORDER_ID_PATTERN)

    unless match
      Rails.logger.warn("[SePay] Could not parse order_invoice_number: #{order_id}")
      return
    end

    sku = match[1]
    account_id = match[2].to_i

    @record = SubscriptionPlan.find_by(sku: sku) || AddonPackage.find_by(sku: sku)
    @account = Account.find_by(id: account_id)

    Rails.logger.warn("[SePay] Record not found for SKU: #{sku}") if @record.blank?
    Rails.logger.warn("[SePay] Account not found for ID: #{account_id}") if @account.blank?
  end

  def activate_plan
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
    product_name = @record.is_a?(SubscriptionPlan) ? @record.name(@account.locale) : @record.name
    transaction_ref = payload['transaction_id'].to_s.presence || payload['id'].to_s

    @account.billing_histories.create!(
      price_amount: payload['order_amount'].to_i,
      price_currency: payload['currency'] || 'VND',
      product_name: product_name,
      sku: @record.sku,
      status: 0,
      product_id: @record.id.to_s,
      metadata: {
        type: @record.is_a?(SubscriptionPlan) ? 'package' : 'addon',
        sku: @record.sku,
        id: @record.id,
        payment_method: 'sepay'
      },
      transaction_id: transaction_ref,
      description: payload['order_description'],
      transaction_date_time: payload['paid_at'] || payload['created_at']
    )
  end
end
