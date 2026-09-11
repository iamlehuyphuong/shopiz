# frozen_string_literal: true

# Handles SePay Payment Gateway webhook (IPN) events
# Parses order_invoice_number to extract SKU and account ID
# order_invoice_number format: SHOPIZ<SKU>A<ACCOUNT_ID>T<TIMESTAMP>
class Enterprise::Billing::HandleSepayEventService
  ORDER_ID_PATTERN = /\ASHOPIZ(.+)A(\d+)T\d+\z/i

  def perform(payload, parsed_data = nil)
    # Fallback if parsed_data is not provided (e.g., from old tests)
    unless parsed_data
      config = {
        'company_code' => GlobalConfig.get_value('SEPAY_COMPANY_CODE').presence || ENV.fetch('SEPAY_COMPANY_CODE', nil),
        'secret_key' => GlobalConfig.get_value('SEPAY_SECRET_KEY').presence || ENV.fetch('SEPAY_SECRET_KEY', nil)
      }
      provider = Payments::Providers::SepayProvider.new(config)
      parsed_data = provider.extract_webhook_data(payload)
    end

    prepare_data(payload, parsed_data)
    if @account.blank? || @record.blank?
      Rails.logger.error("[SePay] Aborting perform due to missing account or record. Payload: #{payload.inspect}")
      return
    end

    ActiveRecord::Base.transaction do
      @record.is_a?(SubscriptionPlan) ? activate_plan : activate_addon
      billing_history = save_billing_history(payload, parsed_data)
      Enterprise::Billing::IssueSepayEinvoiceJob.perform_later(billing_history.id)
    end
  end

  private

  def prepare_data(payload, parsed_data)
    order_id = parsed_data[:transaction_id].to_s.strip.upcase

    # If order_invoice is present, we can reliably find the exact bill (pending or completed duplicate)
    # If it's missing and we use content, we should only look for pending bills to avoid matching old completed bills
    order_invoice = payload.dig('order', 'order_invoice_number')
    @pending_bill = if order_invoice.present?
                      BillingHistory.find_by(order_id: order_id)
                    else
                      BillingHistory.find_by(order_id: order_id, status: :pending)
                    end

    if @pending_bill.present?
      @account = @pending_bill.account
      @record = SubscriptionPlan.find_by(sku: @pending_bill.sku) || AddonPackage.find_by(sku: @pending_bill.sku)
      return
    end

    # Fallback for old orders
    match = order_id.match(ORDER_ID_PATTERN)
    unless match
      Rails.logger.warn("[SePay] Could not parse order_invoice_number: #{order_id}")
      return
    end

    sku = match[1]
    account_id = match[2].to_i

    @account = Account.find_by(id: account_id)
    # Fallback: find the last pending bill for this account to get the accurate sku
    @pending_bill = @account&.billing_histories&.where(status: :pending)&.last

    @record = if @pending_bill.present?
                SubscriptionPlan.find_by(sku: @pending_bill.sku) || AddonPackage.find_by(sku: @pending_bill.sku)
              else
                SubscriptionPlan.find_by(sku: sku) || AddonPackage.find_by(sku: sku)
              end

    Rails.logger.warn("[SePay] Record not found for SKU: #{sku} (or pending bill)") if @record.blank?
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

  def save_billing_history(payload, parsed_data)
    transaction_ref = parsed_data[:gateway_transaction_id]
    transaction_date_time = payload.dig('transaction', 'transaction_date') || payload['transactionDate'] || payload['timestamp']
    parsed_paid_at = begin
      Time.zone.parse(transaction_date_time.to_s)
    rescue StandardError
      Time.current
    end

    if @pending_bill.present?
      @pending_bill.update!(
        status: :completed,
        transaction_id: transaction_ref,
        gateway_payload: payload,
        paid_at: parsed_paid_at,
        transaction_date_time: transaction_date_time
      )
      @pending_bill
    else
      product_name = @record.is_a?(SubscriptionPlan) ? @record.name(@account.locale) : @record.name
      price_amount = parsed_data[:amount]
      order_id_raw = parsed_data[:transaction_id]

      @account.billing_histories.create!(
        price_amount: price_amount.to_i,
        price_currency: payload.dig('order', 'order_currency') || 'VND',
        product_name: product_name,
        sku: @record.sku,
        status: :completed,
        product_id: @record.id.to_s,
        metadata: {
          type: @record.is_a?(SubscriptionPlan) ? 'package' : 'addon',
          sku: @record.sku,
          id: @record.id,
          payment_method: 'sepay'
        },
        transaction_id: transaction_ref,
        description: payload.dig('order', 'order_description'),
        transaction_date_time: transaction_date_time,
        payment_method: 'sepay',
        gateway_payload: payload,
        paid_at: parsed_paid_at,
        order_id: order_id_raw.to_s.strip.upcase
      )
    end
  end
end
