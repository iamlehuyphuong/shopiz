class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  before_action :set_config
  before_action :allowed_configs
  def show
    # ref: https://github.com/rubocop/rubocop/issues/7767
    # rubocop:disable Style/HashTransformValues
    @app_config = InstallationConfig.where(name: @allowed_configs)
                                    .pluck(:name, :serialized_value)
                                    .map { |name, serialized_value| [name, serialized_value['value']] }
                                    .to_h
    # rubocop:enable Style/HashTransformValues
    @installation_configs = ConfigLoader.new.general_configs.each_with_object({}) do |config_hash, result|
      result[config_hash['name']] = config_hash.except('name')
    end
  end

  def create
    errors = []
    params['app_config'].each do |key, value|
      next unless @allowed_configs.include?(key)

      i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      i.value = value
      errors.concat(i.errors.full_messages) unless i.save
    end

    if errors.any?
      redirect_to super_admin_app_config_path(config: @config), alert: errors.join(', ')
    else
      redirect_to super_admin_settings_path, notice: "App Configs - #{@config.titleize} updated successfully"
    end
  end

  private

  def set_config
    @config = params[:config] || 'general'
  end

  def allowed_configs
    mapping = {
      'facebook' => %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET IG_VERIFY_TOKEN FACEBOOK_API_VERSION ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT],
      'shopify' => %w[SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET],
      'microsoft' => %w[AZURE_APP_ID AZURE_APP_SECRET],
      'email' => %w[MAILER_INBOUND_EMAIL_DOMAIN ACCOUNT_EMAILS_LIMIT ACCOUNT_EMAILS_PLAN_LIMITS],
      'linear' => %w[LINEAR_CLIENT_ID LINEAR_CLIENT_SECRET],
      'slack' => %w[SLACK_CLIENT_ID SLACK_CLIENT_SECRET],
      'instagram' => %w[INSTAGRAM_APP_ID INSTAGRAM_APP_SECRET INSTAGRAM_VERIFY_TOKEN INSTAGRAM_API_VERSION ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT],
      'tiktok' => %w[TIKTOK_APP_ID TIKTOK_APP_SECRET TIKTOK_API_VERSION],
      'whatsapp_embedded' => %w[WHATSAPP_APP_ID WHATSAPP_APP_SECRET WHATSAPP_CONFIGURATION_ID WHATSAPP_API_VERSION],
      'notion' => %w[NOTION_CLIENT_ID NOTION_CLIENT_SECRET],
      'google' => %w[GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET GOOGLE_OAUTH_REDIRECT_URI ENABLE_GOOGLE_OAUTH_LOGIN],
      'captain' => %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL CAPTAIN_OPEN_AI_ENDPOINT],
      'zalo' => %w[ZALO_OA_APP_ID ZALO_OA_APP_SECRET ZALO_OA_SECRET_KEY],
      'zalo_personal' => %w[ZALO_API_URL ZALO_API_KEY ZALO_SECRET_KEY],
      'tiktok_shop' => %w[TIKTOK_SHOP_APP_ID TIKTOK_SHOP_APP_KEY TIKTOK_SHOP_APP_SECRET],
      'payos' => %w[PAYOS_CLIENT_ID PAYOS_API_KEY PAYOS_CHECKSUM_KEY PAYOS_PARTNER_ID],
      'sepay' => %w[SEPAY_COMPANY_CODE SEPAY_SECRET_KEY SEPAY_EINVOICE_ENABLED SEPAY_EINVOICE_PROVIDER_ACCOUNT_ID SEPAY_EINVOICE_TEMPLATE_CODE SEPAY_EINVOICE_INVOICE_SERIES SEPAY_EINVOICE_CLIENT_ID SEPAY_EINVOICE_CLIENT_SECRET],
      'payment' => %w[PAYMENT_GATEWAY_VN_DEFAULT PAYMENT_GATEWAY_INTL_DEFAULT PAYMENT_GATEWAY_PAYOS_ENABLED PAYMENT_GATEWAY_SEPAY_ENABLED PAYMENT_GATEWAY_POLAR_ENABLED POLAR_API_KEY POLAR_WEBHOOK_SECRET POLAR_GENERIC_PRODUCT_ID EXCHANGE_RATE_VND_USD],
      'channels' => %w[
        CHANNEL_STATUS_FACEBOOK CHANNEL_STATUS_ZALO_OA CHANNEL_STATUS_ZALO_PERSONAL CHANNEL_STATUS_TIKTOK CHANNEL_STATUS_TIKTOK_SHOP CHANNEL_STATUS_WHATSAPP CHANNEL_STATUS_INSTAGRAM CHANNEL_STATUS_TELEGRAM CHANNEL_STATUS_LINE CHANNEL_STATUS_TWITTER CHANNEL_STATUS_WEBSITE
      ],
      'integrations' => %w[
        INTEGRATION_STATUS_WEBHOOK INTEGRATION_STATUS_DASHBOARD_APPS INTEGRATION_STATUS_OPENAI INTEGRATION_STATUS_LINEAR INTEGRATION_STATUS_NOTION INTEGRATION_STATUS_SLACK INTEGRATION_STATUS_DIALOGFLOW INTEGRATION_STATUS_GOOGLE_TRANSLATE INTEGRATION_STATUS_DYTE INTEGRATION_STATUS_OMICALL
      ],
      'sales_softwares' => %w[
        INTEGRATION_STATUS_SHOPIFY INTEGRATION_STATUS_KIOTVIET INTEGRATION_STATUS_HARAVAN INTEGRATION_STATUS_WOOCOMMERCE INTEGRATION_STATUS_SAPO INTEGRATION_STATUS_NHANHVN INTEGRATION_STATUS_CALENDLY INTEGRATION_STATUS_GOOGLE_CALENDAR INTEGRATION_STATUS_LEADSQUARED
      ],
    }

    @allowed_configs = mapping.fetch(
      @config,
      %w[ENABLE_ACCOUNT_SIGNUP FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS WEBHOOK_TIMEOUT MAXIMUM_FILE_UPLOAD_SIZE WIDGET_TOKEN_EXPIRY]
    )
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
