# frozen_string_literal: true

class Enterprise::Billing::HandleVnpayEventService
  def perform(event:)
    prepare_data(event)
    return if @account.blank? || @record.blank?

    ActiveRecord::Base.transaction do
      @record.is_a?(SubscriptionPlan) ? activate_plan : activate_addon
      save_billing_history(event)
    end
  end

  private

  def prepare_data(event)
    order_info = event['vnp_OrderInfo'].to_s
    # Extract SKU and account_id from order info
    # Format: "TT SHOPIZ [SKU]" or legacy format with product_id/customer_id
    match = order_info.match(/customer_id=(\d+)/)
    @customer_id = match ? match[1] : nil

    # Try to extract SKU from new format or fallback
    sku = extract_sku(order_info)
    @record = SubscriptionPlan.find_by(sku: sku) || AddonPackage.find_by(sku: sku) if sku.present?

    # Fallback: try product_id from legacy format
    if @record.blank?
      product_match = order_info.match(/product_id=(\d+)/)
      if product_match
        product_id = product_match[1]
        @record = SubscriptionPlan.find_by(id: product_id) || AddonPackage.find_by(id: product_id)
      end
    end

    @account = Account.find_by(id: @customer_id)
  end

  def extract_sku(order_info)
    # Try "sku=XXX" format
    sku_match = order_info.match(/sku=([^\s|]+)/)
    return sku_match[1] if sku_match

    # Fallback: extract from description
    nil
  end

  def activate_plan
    Subscriptions::SubscribeService.new(@account, @record).execute
  end

  def activate_addon
    Addons::PurchaseService.new(@account, @record).execute
  end

  def save_billing_history(event)
    product_name = @record.is_a?(SubscriptionPlan) ? @record.name(@account.locale) : @record.name

    @account.billing_histories.create!(
      price_amount: event['vnp_Amount'].to_i / 100, # VNPay sends amount in smallest unit
      price_currency: 'vnd',
      product_name: product_name,
      sku: @record.respond_to?(:sku) ? @record.sku : "#{@record.class.name}_#{@record.id}",
      status: 0,
      product_id: @record.id.to_s,
      metadata: {
        type: @record.is_a?(SubscriptionPlan) ? 'package' : 'addon',
        sku: @record.respond_to?(:sku) ? @record.sku : nil,
        id: @record.id,
        payment_method: 'vnpay'
      },
      transaction_id: event['vnp_TransactionNo'],
      description: event['vnp_OrderInfo'],
      transaction_date_time: event['vnp_PayDate']
    )
  end
end
