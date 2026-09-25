# frozen_string_literal: true

class Enterprise::Billing::HandlePolarEventService
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
    # Payload metadata is merged into data for order.created or checkout.completed
    metadata = payload.dig('data', 'metadata') || payload.dig('data', 'checkout', 'metadata') || {}
    order_id = metadata['order_id']

    if order_id.blank?
      Rails.logger.warn('[Polar] No order_id found in metadata. Cannot process.')
      return
    end

    @pending_bill = BillingHistory.find_by(order_id: order_id)
    if @pending_bill.blank?
      Rails.logger.warn("[Polar] Pending bill not found for order_id: #{order_id}")
      return
    end

    @account = @pending_bill.account
    @record = SubscriptionPlan.find_by(sku: @pending_bill.sku) || AddonPackage.find_by(sku: @pending_bill.sku)

    Rails.logger.warn("[Polar] Record not found for SKU: #{@pending_bill.sku}") if @record.blank?
    Rails.logger.warn("[Polar] Account not found for ID: #{@account&.id}") if @account.blank?
  end

  def activate_plan
    sub = @account.active_subscription
    if sub && same_tier?(sub.subscription_plan, @record)
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
    payload.dig('data', 'amount') || payload.dig('data', 'checkout', 'amount')
    transaction_ref = payload.dig('data', 'id')
    created_at = payload.dig('data', 'created_at')

    parsed_paid_at = begin
      Time.zone.parse(created_at.to_s)
    rescue StandardError
      Time.current
    end

    @pending_bill.update!(
      status: :completed,
      transaction_id: transaction_ref,
      gateway_payload: payload,
      paid_at: parsed_paid_at,
      transaction_date_time: created_at
    )
  end
end
