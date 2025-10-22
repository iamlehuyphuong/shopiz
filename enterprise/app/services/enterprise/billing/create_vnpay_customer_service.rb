class Enterprise::Billing::CreateVnpayCustomerService
  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 1

  def perform
    customer_id = prepare_customer_id

    plan = find_plan(default_plan['product_id'].first) if default_plan['product_id'].present?
    return if plan.blank? || account.blank?

    days = ((plan['months'].to_f || 0 ) * 30 ).to_i
    subscription = {
      'plan' => {
        'id' => price_id,
        'product' => default_plan['product_id'].first
      },
      'status' => 'active',
      'current_period_end' => Time.now.to_i + days.days,
      'quantity' => plan['limits']['agents']
    }
    account.update!(
      custom_attributes: {
        stripe_customer_id: customer_id,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: default_plan['name'],
        subscribed_quantity: subscription['quantity'],
        subscription_status: subscription['status'],
        subscription_ends_on: Time.zone.at(subscription['current_period_end'])
      }
    )
    account.limits = plan['limits'] || {}
    features = plan['features'] || []
    account.enable_features(*features)
    account.reset_response_usage
    account.save
  end

  private

  def prepare_customer_id
    customer_id = account.custom_attributes['stripe_customer_id']
    if customer_id.blank?
      customer_id = account.id
    end
    customer_id
  end

  def default_quantity
    default_plan['default_quantity'] || DEFAULT_QUANTITY
  end

  def billing_email
    account.administrators.first.email
  end

  def default_plan
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    @default_plan ||= installation_config.value.first
  end

  def price_id
    price_ids = default_plan['price_ids']
    price_ids.first
  end

  def find_plan(plan_id)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    plan = installation_config.value.find { |config| config['product_id'].include?(plan_id) }
    return nil if plan.blank?
    Polar.configure do |config|
      config.access_token = ENV['POLAR_ACCESS_TOKEN']
      config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
    end
    product = Polar::Product.get(plan_id)
    product = product.table
    plan['features'] = product[:metadata]['features'].split(',').map(&:strip) if product[:metadata].present? && product[:metadata]['features'].present?
    plan['months'] = product[:metadata]['months'] if product[:metadata].present? && product[:metadata]['months'].present?
    plan['inboxes'] = product[:metadata]['inboxes'] if product[:metadata].present? && product[:metadata]['inboxes'].present?
    
    plan['limits'] = {
      'inboxes' => product[:metadata]['inboxes'] || 1,
      'agents' => product[:metadata]['agents'] || 1,
      'captain_responses' => product[:metadata]['captain_responses'] || 0,
      'captain_documents' => product[:metadata]['captain_documents'] || 0
    }
    plan
  rescue Polar::NotFoundError => e
    Rails.logger.error { "Plan not found for ID: #{plan_id}, Error: #{e.message}" }
    nil
  rescue StandardError => e
    Rails.logger.error { "Error fetching plan for ID: #{plan_id}, Error: #{e.message}" }
    nil
  end
end
