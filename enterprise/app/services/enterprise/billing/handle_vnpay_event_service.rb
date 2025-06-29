class Enterprise::Billing::HandleVnpayEventService
  CAPTAIN_RESPONSES = 'captain_responses'.freeze
  CAPTAIN_DOCUMENTS = 'captain_documents'.freeze
  CAPTAIN_RESPONSES_USAGE = 'captain_responses_usage'.freeze
  CAPTAIN_DOCUMENTS_USAGE = 'captain_documents_usage'.freeze

  def perform(event:)
    ensure_event_context(event)
    case @event.type
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def process_subscription_updated
    plan = find_plan(subscription['plan']['product']) if subscription['plan'].present?

    # skipping self hosted plan events
    return if plan.blank? || account.blank?

    update_account_attributes(subscription, plan)

    change_plan_features(plan)
    update_limits(plan)
    reset_captain_usage
  end

  def update_account_attributes(subscription, plan)
    # https://stripe.com/docs/api/subscriptions/object

    account.update(
      custom_attributes: {
        stripe_customer_id: subscription.customer,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: plan['name'],
        subscribed_quantity: subscription['quantity'],
        subscription_status: subscription['status'],
        subscription_ends_on: Time.zone.at(subscription['current_period_end'])
      }
    )
  end

  def process_subscription_deleted
    # skipping self hosted plan events
    return if account.blank?

    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end

  def change_plan_features(plan)
    if default_plan?
      account.disable_features(*features_to_update)
    else
      features = plan['features'] || []
      account.enable_features(*features)
    end
    account.save!
  end

  def update_limits(plan)
    account.limits = plan['limits'] || {}
    account.save!
  end

  def reset_captain_usage
    account.reset_response_usage
  end

  def ensure_event_context(event)
    orderInfo = event['vnp_OrderInfo']
    match_data = orderInfo.match(/Thanh toán cho Shopiz - Gói (?<product_name>.+?) - Tham số: product_id=(?<product_id>[^|]+)\|\|price_id=(?<price_id>[^|]+)\|\|customer_id=(?<customer_id>.+)/)
    raise 'Invalid orderInfo format' unless match_data

    product = { name: match_data[:product_name], id: match_data[:product_id] }
    price = { 'id' => match_data[:price_id] }
    customer_id = match_data[:customer_id]

    plan = find_plan(product[:id])
    days = (plan['months'].to_i || 0) * 30
    event = {
      type: 'customer.subscription.updated',
      data: {
        object: {
          customer: customer_id,
          plan: {
            id: price[:id],
            product: product[:id]
          },
          quantity: plan['limits']['agents'],
          status: 'active',
          current_period_end: Time.now.to_i + days.days
        }
      }
    }
    @event = JSON.parse(event.to_json, object_class: OpenStruct)
  end

  def features_to_update
    %w[inbound_emails help_center campaigns team_management channel_twitter channel_facebook channel_email channel_api channel_zalopersonal
       channel_line channel_telegram channel_whatsapp channel_sms captain_integration]
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?",
                               subscription.customer).first || Account.find_by(id: subscription.customer)
  end

  def find_plan(plan_id)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    plan = installation_config.value.find { |config| config['product_id'].include?(plan_id) }
    return nil if plan.blank?

    Polar.configure do |config|
      config.access_token = ENV.fetch('POLAR_ACCESS_TOKEN', nil)
      config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
    end
    product = Polar::Product.get(plan_id)
    product = product.table
    if product[:metadata].present? && product[:metadata]['features'].present?
      plan['features'] =
        product[:metadata]['features'].split(',').map(&:strip)
    end
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

  def default_plan?
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    default_plan = installation_config.value.first
    @account.custom_attributes['plan_name'] == default_plan['name']
  end
end
