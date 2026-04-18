class Enterprise::Api::V1::AccountsController < Api::BaseController
  include BillingHelper
  before_action :fetch_account
  before_action :check_authorization
  before_action :check_cloud_env, only: [:billings, :limits, :toggle_deletion]

  def subscription
    # Ensure account has a subscription - assign free plan if none exists
    unless @account.active_subscription.present?
      free_plan = SubscriptionPlan.free_plan.first
      Subscriptions::SubscribeService.new(@account, free_plan).execute if free_plan
    end
    head :no_content
  end

  def limits
    limits = {
      inboxes: {
        allowed: @account.limits['inboxes'].to_i,
        consumed: @account.inboxes.count
      },
      agents: {
        allowed: @account.limits['agents'].to_i,
        consumed: @account.users.count
      },
      contacts: {
        allowed: @account.limits['contacts'].to_i,
        consumed: @account.contacts.count
      },
      automations: {
        allowed: @account.limits['automations'].to_i,
        consumed: @account.automation_rules.count
      },
      captain: @account.usage_captain_summary
    }

    # include id in response to ensure that the store can be updated on the frontend
    render json: { id: @account.id, limits: limits }, status: :ok
  end

  def billings
    data = ::BillingPresenter.new(@account).json_data
    render json: { id: @account.id, data: data }, status: :ok
  end

  def checkout
    method = resolve_payment_method
    attempt_checkout_with_fallback(method)
  end

  def toggle_deletion
    action_type = params[:action_type]

    case action_type
    when 'delete'
      mark_for_deletion
    when 'undelete'
      unmark_for_deletion
    else
      render json: { error: 'Invalid action_type. Must be either "delete" or "undelete"' }, status: :unprocessable_entity
    end
  end

  def topup_checkout
    return render json: { error: I18n.t('errors.topup.credits_required') }, status: :unprocessable_entity if params[:credits].blank?

    service = Enterprise::Billing::TopupCheckoutService.new(account: @account)
    result = service.create_checkout_session(credits: params[:credits].to_i)

    @account.reload
    render json: result.merge(
      id: @account.id,
      limits: @account.limits,
      custom_attributes: @account.custom_attributes
    )
  rescue Enterprise::Billing::TopupCheckoutService::Error, Stripe::StripeError => e
    render_could_not_create_error(e.message)
  end

  private

  def check_cloud_env
    render json: { error: 'Not found' }, status: :not_found unless ChatwootApp.chatwoot_cloud?
  end

  def default_limits
    {
      'conversation' => {},
      'non_web_inboxes' => {},
      'agents' => {
        'allowed' => @account.usage_limits[:agents],
        'consumed' => agents(@account)
      },
      'captain' => @account.usage_limits[:captain]
    }
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def mark_for_deletion
    reason = 'manual_deletion'

    if @account.mark_for_deletion(reason)
      cancel_cloud_subscriptions_for_deletion

      render json: { message: 'Account marked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unmark_for_deletion
    if @account.unmark_for_deletion
      render json: { message: 'Account unmarked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def resolve_payment_method
    method = params[:payment_method]
    return method if method.present? && %w[payos sepay polar stripe].include?(method)

    # Auto-resolve based on account locale and config
    router = Enterprise::Billing::PaymentRouter.new(@account)
    router.resolve
  end

  def attempt_checkout_with_fallback(method)
    attempt_checkout(method)
  rescue StandardError => e
    Rails.logger.warn("[Checkout] #{method} failed: #{e.class} - #{e.message}")
    router = Enterprise::Billing::PaymentRouter.new(@account)
    fallback = router.next_fallback(method)

    if fallback
      Rails.logger.info("[Checkout] Falling back from #{method} to #{fallback}")
      begin
        attempt_checkout(fallback)
      rescue StandardError => fallback_error
        Rails.logger.error("[Checkout] Fallback #{fallback} also failed: #{fallback_error.message}")
        render_could_not_create_error("Payment failed. Please try again later.")
      end
    else
      render_could_not_create_error("Payment failed. Please try again later.")
    end
  end

  def attempt_checkout(method)
    case method
    when 'stripe'
      create_stripe_billing_session(stripe_customer_id)
    when 'payos'
      create_payos_billing_session
    when 'sepay'
      create_sepay_checkout_info
    when 'polar'
      create_polar_billing_session
    else
      raise StandardError, 'No valid payment method available'
    end
  end

  def create_polar_billing_session
    url = Enterprise::Billing::CreateSessionService.new.create_polar_session(
      @account.id,
      params[:product_id],
      product_type: params[:product_type]
    )
    raise StandardError, 'Polar checkout failed - no payment link returned' if url.blank?

    render_redirect_url(url)
  end

  def create_stripe_billing_session(customer_id)
    session = Enterprise::Billing::CreateSessionService.new.create_session(customer_id)
    render_redirect_url(session.url)
  end

  def create_sepay_checkout_info
    result = Enterprise::Billing::CreateSessionService.new.create_sepay_checkout(
      @account.id,
      params[:product_id],
      product_type: params[:product_type]
    )
    raise StandardError, 'SePay checkout failed - no checkout URL returned' if result.blank? || result[:checkout_url].blank?

    render json: {
      redirect_url: result[:checkout_url],
      form_params: result[:form_params],
      method: 'POST'
    }, status: :ok
  end

  def create_payos_billing_session
    url = Enterprise::Billing::CreateSessionService.new.create_payos_session(
      @account.id,
      params[:product_id],
      product_type: params[:product_type]
    )
    raise StandardError, 'PayOS checkout failed - no payment link returned' if url.blank?

    render_redirect_url(url)
  end

  def cancel_cloud_subscriptions_for_deletion
    Enterprise::Billing::CancelCloudSubscriptionsService.new(account: @account).perform
  rescue Stripe::StripeError => e
    Rails.logger.warn("Failed to cancel cloud subscriptions for account #{@account.id}: #{e.class} - #{e.message}")
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
