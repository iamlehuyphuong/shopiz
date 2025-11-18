class Enterprise::Billing::HandlePayosEventService
  def perform(payload)
    prepare_data(payload)
    return if @account.blank? || @product.blank?

    ActiveRecord::Base.transaction do
      @product[:metadata]['type'] == 'package' ? update_plan : update_credit
      save_billing_history(payload)
    end
  end

  private

  def prepare_data(payload)
    name = payload.dig('data', 'description').to_s.split.last
    @product = Polar::ProductService.by_name(name&.downcase)&.with_indifferent_access
    @customer_id = payload['data']['orderCode'].to_s[10..].to_s
    @account = Account.find_by(id: @customer_id)
  end

  def update_plan
    update_custom_attributes
    change_plan_features
    update_limits
  end

  def update_credit
    new_credit = @account.limits['captain_responses_credit'].to_i + @product[:metadata]['captain_responses_credit'].to_i
    @account.limits['captain_responses_credit'] = new_credit
    @account.save
  end

  def update_custom_attributes
    @account.update(custom_attributes: build_custom_attributes)
  end

  def build_custom_attributes
    {
      stripe_customer_id: @customer_id,
      stripe_price_id: @product[:prices][0]['id'],
      stripe_product_id: @product[:id],
      plan_name: @product[:name],
      sku: @product[:metadata]['sku'],
      subscribed_quantity: @product[:metadata]['agents'],
      subscription_status: :active,
      subscription_ends_on: subscription_ends_on
    }
  end

  def subscription_ends_on
    current_plan = @account.custom_attributes['plan_name']
    number_of_months = @product[:metadata]['months'].to_i

    if current_plan == @product[:name]
      base_time = [Time.zone.now, Time.zone.parse(@account.custom_attributes['subscription_ends_on'])].max
      base_time + number_of_months.months
    else
      Time.zone.now + number_of_months.months
    end
  end

  def change_plan_features
    @account.disable_features(*Featurable::MAPPING.values)

    features = @product[:metadata]['features']&.split(',')&.map(&:strip) || []
    mapping_features = features.map { |item| Featurable::MAPPING[item.to_sym] }
    @account.enable_features(*mapping_features)
    @account.save!
  end

  def update_limits
    @account.limits = build_limits
    @account.save!
  end

  def build_limits
    metadata = @product[:metadata]

    {
      captain_assistants: metadata['captain_assistants'].to_i,
      captain_responses: metadata['captain_responses'].to_i,
      captain_documents: metadata['captain_documents'].to_i,
      captain_faqs: metadata['captain_faqs'].to_i,
      contacts: metadata['contacts'].to_i,
      inboxes: metadata['inboxes'].to_i,
      agents: metadata['agents'].to_i,
      automations: metadata['automations'].to_i
    }
  end

  def reset_captain_usage
    @account.reset_response_usage
  end

  def save_billing_history(payload)
    data = payload['data']

    @account.billing_histories.create!(
      price_amount: data['amount'],
      price_currency: data['currency'],
      product_name: @product[:name],
      sku: @product[:metadata]['sku'],
      status: 0,
      product_id: @product[:id],
      metadata: @product[:metadata],
      transaction_id: data['reference'],
      description: data['description'],
      transaction_date_time: data['transactionDateTime']
    )
  end
end
