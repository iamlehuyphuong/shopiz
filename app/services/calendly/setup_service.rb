# Verifies a Calendly PAT by calling /users/me and populates
# user_uri, organization_uri, and user_name on the hook settings.
# Called after a Calendly integration hook is created.
class Calendly::SetupService
  def initialize(hook)
    @hook = hook
  end

  def setup
    token = @hook.merged_settings['access_token']
    return unless token.present?

    client = Calendly::ApiClient.new(token)

    # 1. Verify token + fetch user info
    user_data = client.current_user
    resource = user_data['resource']

    return unless resource

    # 2. Populate settings with verified data
    @hook.update!(
      settings: @hook.settings.merge(
        'user_uri' => resource['uri'],
        'organization_uri' => resource['current_organization'],
        'user_name' => resource['name'],
        'default_timezone' => @hook.settings['default_timezone'] || resource['timezone'] || 'Asia/Ho_Chi_Minh'
      )
    )

    Rails.logger.info "Calendly: Setup completed for hook ##{@hook.id} — user: #{resource['name']}"

    # 3. Register webhook subscription (optional, will be enhanced in Phase 3)
    register_webhook(client, resource['current_organization'])
  rescue Calendly::ApiClient::ApiError => e
    Rails.logger.error "Calendly: Setup failed for hook ##{@hook.id} — #{e.message}"
    @hook.update!(status: :disabled)
    raise
  end

  private

  def register_webhook(client, organization_uri)
    return unless organization_uri.present?

    webhook_url = build_webhook_url
    return unless webhook_url

    response = client.create_webhook_subscription(
      url: webhook_url,
      events: %w[invitee.created invitee.canceled],
      organization_uri: organization_uri
    )

    webhook_uri = response.dig('resource', 'uri')
    if webhook_uri
      @hook.update!(
        settings: @hook.settings.merge('webhook_subscription_uri' => webhook_uri)
      )
      Rails.logger.info "Calendly: Webhook registered for hook ##{@hook.id}"
    end
  rescue Calendly::ApiClient::ApiError => e
    # Webhook registration failure is non-critical; log and continue
    Rails.logger.warn "Calendly: Webhook registration failed for hook ##{@hook.id} — #{e.message}"
  end

  def build_webhook_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    return nil unless frontend_url.present?

    "#{frontend_url}/webhooks/calendly"
  end
end
