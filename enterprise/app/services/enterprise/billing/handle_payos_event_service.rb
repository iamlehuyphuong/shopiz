class Enterprise::Billing::HandlePayosEventService
  FEATURES_TO_UPDATE = %w[
    inbound_emails
    help_center
    campaigns
    team_management
    channel_twitter
    channel_facebook
    channel_email
    channel_api
    channel_zalopersonal
    channel_line
    channel_telegram
    channel_whatsapp
    captain_integration
  ].freeze

  def perform(payload)
    prepare_data(payload)
    process_subscription_updated
  end

  private

  def prepare_data(payload)
    name, duration = payload.dig('data', 'description').to_s.split[2..]
    return if name.blank? || duration.blank?

    @product_id = Enterprise::Billing::PlanMapper.get_product_id(name, duration)
    raise 'Invalid description format' unless @product_id

    @plan = find_and_build_plan(@product_id)
    raise 'Plan not found' if @plan.blank?

    @customer_id = payload['data']['orderCode'].to_s[10..].to_s
    build_event_data
  end

  def build_event_data
    product_info = load_product_info(@product_id)
    days = (@plan['months'].to_i || 0) * 30

    event = {
      type: 'customer.subscription.updated',
      data: {
        object: {
          customer: @customer_id,
          plan: {
            id: product_info[:prices][0]['id'],
            product: product_info[:id]
          },
          quantity: @plan['limits']['agents'],
          status: 'active',
          current_period_end: Time.now.to_i + days.days
        }
      }
    }
    @event = JSON.parse(event.to_json, object_class: OpenStruct)
  end

  def process_subscription_updated
    return if @plan.blank? || account.blank?

    update_account_attributes
    change_plan_features
    update_limits
    reset_captain_usage
  end

  def update_account_attributes
    account.update(
      custom_attributes: {
        stripe_customer_id: subscription.customer,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: @plan['name'],
        subscribed_quantity: subscription['quantity'],
        subscription_status: subscription['status'],
        subscription_ends_on: Time.zone.at(subscription['current_period_end'])
      }
    )
  end

  def change_plan_features
    if default_plan?
      account.disable_features(*FEATURES_TO_UPDATE)
    else
      features = @plan['features'] || []
      account.enable_features(*features)
    end
    account.save!
  end

  def update_limits
    account.limits = @plan['limits'] || {}
    account.save!
  end

  def reset_captain_usage
    account.reset_response_usage
  end

  def find_and_build_plan(product_id)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    plan = installation_config.value.find { |config| config['product_id'].include?(product_id) }
    return if plan.blank?

    product = load_product_info(product_id)
    metadata = product[:metadata]
    if metadata.present?
      plan['features'] = metadata['features'].split(',').map(&:strip) if metadata['features'].present?
      plan['months'] = metadata['months'] if metadata['months'].present?
      plan['inboxes'] = metadata['inboxes'] if metadata['inboxes'].present?
      plan['limits'] = {
        'inboxes' => metadata['inboxes'] || 1,
        'agents' => metadata['agents'] || 1,
        'captain_responses' => metadata['captain_responses'] || 0,
        'captain_documents' => metadata['captain_documents'] || 0
      }
    end

    plan
  end

  def load_product_info(product_id)
    return @product if defined?(@product) && @product[:id] == product_id

    Polar.configure do |config|
      config.access_token = ENV.fetch('POLAR_ACCESS_TOKEN', nil)
      config.sandbox = ENV['POLAR_ENV'] == 'sandbox'
    end
    product = Polar::Product.get(product_id)
    @product = product.table
  rescue StandardError => e
    Rails.logger.error { "Error fetching product for ID: #{product_id}, Error: #{e.message}" }
    {}
  end

  def default_plan?
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    default_plan = installation_config.value.first
    account.custom_attributes['plan_name'] == default_plan['name']
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= Account.find_by(id: subscription.customer)
  end
end
