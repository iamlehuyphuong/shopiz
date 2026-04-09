class Enterprise::Billing::HandlePayosEventService
  def perform(payload)
    prepare_data(payload)
    return if @account.blank? || @record.blank?

    ActiveRecord::Base.transaction do
      @record.is_a?(SubscriptionPlan) ? update_plan : update_addon
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

  def update_plan
    @account.update!(
      limits: @account.limits.merge(@record.limits),
      custom_attributes: @account.custom_attributes.merge(
        plan_name: @record.name(@account.locale),
        sku: @record.sku,
        subscription_status: 'active',
        subscription_ends_on: (Time.zone.now + @record.duration_days.days).to_s
      )
    )
    # Handle features
    all_feature_names = Featurable::FEATURE_LIST.map { |f| f['name'] }
    @account.disable_features(*all_feature_names)
    @record.features.each do |feature, enabled|
      enabled ? @account.enable_features(feature) : @account.disable_features(feature)
    end
    @account.save!
  end

  def update_addon
    case @record.addon_type
    when 'ai_messages'
      current = @account.limits['captain_responses_credit'].to_i
      @account.limits['captain_responses_credit'] = (current + @record.quantity).to_s
    when 'staff'
      current = @account.limits['agents'].to_i
      @account.limits['agents'] = (current + @record.quantity).to_s
    when 'inboxes_count'
      current = @account.limits['inboxes'].to_i
      @account.limits['inboxes'] = (current + @record.quantity).to_s
    end
    @account.save!
  end

  def save_billing_history(payload)
    data = payload['data']
    product_name = @record.is_a?(SubscriptionPlan) ? @record.name(@account.locale) : @record.name
    
    @account.billing_histories.create!(
      price_amount: data['amount'],
      price_currency: data['currency'] || 'vnd',
      product_name: product_name,
      sku: @record.sku,
      status: 0, # Success
      product_id: @record.id.to_s,
      metadata: {
        type: @record.is_a?(SubscriptionPlan) ? 'package' : 'addon',
        sku: @record.sku,
        id: @record.id
      },
      transaction_id: data['reference'],
      description: data['description'],
      transaction_date_time: data['transactionDateTime']
    )
  end
end
