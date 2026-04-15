# frozen_string_literal: true

class Enterprise::Billing::HandlePayosEventService
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
    sku = payload.dig('data', 'description').to_s.split.last
    @record = SubscriptionPlan.find_by(sku: sku) || AddonPackage.find_by(sku: sku)
    @customer_id = payload['data']['orderCode'].to_s[10..].to_s
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
