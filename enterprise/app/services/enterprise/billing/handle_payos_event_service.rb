# frozen_string_literal: true

class Enterprise::Billing::HandlePayosEventService
  # orderCode format: account_id + 10 digits timestamp

  def perform(payload, parsed_data = nil)
    # Fallback if parsed_data is not provided (e.g., from old tests)
    unless parsed_data
      config = {
        'client_id' => GlobalConfig.get_value('PAYOS_CLIENT_ID').presence || ENV.fetch('PAYOS_CLIENT_ID', nil),
        'api_key' => GlobalConfig.get_value('PAYOS_API_KEY').presence || ENV.fetch('PAYOS_API_KEY', nil),
        'checksum_key' => GlobalConfig.get_value('PAYOS_CHECKSUM_KEY').presence || ENV.fetch('PAYOS_CHECKSUM_KEY', nil),
        'partner_id' => GlobalConfig.get_value('PAYOS_PARTNER_ID').presence || ENV.fetch('PAYOS_PARTNER_ID', nil)
      }
      provider = Payments::Providers::PayosProvider.new(config)
      parsed_data = provider.extract_webhook_data(payload)
    end

    prepare_data(payload, parsed_data)
    if @account.blank? || @record.blank?
      Rails.logger.error("[PayOS] Aborting perform due to missing account or record. Payload: #{payload.inspect}")
      return
    end

    # Idempotency: skip if already processed
    reference = parsed_data[:gateway_transaction_id]
    if reference.present? && @account.billing_histories.exists?(transaction_id: reference)
      Rails.logger.info("[PayOS] Skipping duplicate webhook for reference: #{reference}")
      return
    end

    ActiveRecord::Base.transaction do
      @record.is_a?(SubscriptionPlan) ? activate_plan : activate_addon
      save_billing_history(payload, parsed_data)
    end
  end

  private

  def prepare_data(payload, parsed_data)
    order_code_str = parsed_data[:transaction_id].to_s
    @pending_bill = BillingHistory.find_by(order_id: order_code_str)

    if @pending_bill.present?
      @account = @pending_bill.account
      @record = SubscriptionPlan.find_by(sku: @pending_bill.sku) || AddonPackage.find_by(sku: @pending_bill.sku)
      return
    end

    # Fallback to legacy tracking if no pending bill exists
    description = payload.dig('data', 'description').to_s
    sku_match = description.match(/TT SHOPIZ\s+(.+)/i)
    sku = sku_match ? sku_match[1].strip : nil

    @customer_id = order_code_str.length > 10 ? order_code_str[0...-10].to_i : 0
    @account = Account.find_by(id: @customer_id)

    # Fallback: find the last pending bill for this account to get the accurate sku
    @pending_bill = @account&.billing_histories&.where(status: :pending)&.last

    if @pending_bill.present?
      @record = SubscriptionPlan.find_by(sku: @pending_bill.sku) || AddonPackage.find_by(sku: @pending_bill.sku)
    elsif sku.present?
      @record = SubscriptionPlan.find_by(sku: sku) || AddonPackage.find_by(sku: sku)
    end

    Rails.logger.warn("[PayOS] Record not found for SKU: #{sku} (or pending bill)") if @record.blank?
    Rails.logger.warn("[PayOS] Account not found for parsed ID: #{@customer_id}") if @account.blank?
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

  def save_billing_history(payload, parsed_data)
    data = payload['data']
    transaction_date_time = data['transactionDateTime']

    # Parse transaction date if possible for paid_at
    parsed_paid_at = begin
      Time.zone.parse(transaction_date_time)
    rescue StandardError
      Time.current
    end

    if @pending_bill.present?
      @pending_bill.update!(
        status: :completed,
        transaction_id: parsed_data[:gateway_transaction_id],
        gateway_payload: payload,
        paid_at: parsed_paid_at,
        transaction_date_time: transaction_date_time
      )
    else
      product_name = @record.is_a?(SubscriptionPlan) ? @record.name(@account.locale) : @record.name
      @account.billing_histories.create!(
        price_amount: parsed_data[:amount],
        price_currency: data['currency'] || 'vnd',
        product_name: product_name,
        sku: @record.sku,
        status: :completed,
        product_id: @record.id.to_s,
        metadata: {
          type: @record.is_a?(SubscriptionPlan) ? 'package' : 'addon',
          sku: @record.sku,
          id: @record.id,
          payment_method: 'payos'
        },
        transaction_id: parsed_data[:gateway_transaction_id],
        description: data['description'],
        transaction_date_time: transaction_date_time,
        payment_method: 'payos',
        gateway_payload: payload,
        paid_at: parsed_paid_at,
        order_id: parsed_data[:transaction_id].to_s
      )
    end
  end
end
