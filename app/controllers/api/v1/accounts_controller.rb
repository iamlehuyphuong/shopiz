class Api::V1::AccountsController < Api::BaseController
  include AuthHelper
  include CacheKeysHelper

  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     only: [:create], raise: false
  before_action :check_signup_enabled, only: [:create]
  before_action :ensure_account_name, only: [:create]
  before_action :validate_captcha, only: [:create]
  before_action :fetch_account, except: [:create]
  before_action :check_authorization, except: [:create]

  rescue_from CustomExceptions::Account::InvalidEmail,
              CustomExceptions::Account::InvalidParams,
              CustomExceptions::Account::UserExists,
              CustomExceptions::Account::UserErrors,
              with: :render_error_response

  def show
    @latest_chatwoot_version = ::Redis::Alfred.get(::Redis::Alfred::LATEST_CHATWOOT_VERSION)
    render 'api/v1/accounts/show', format: :json
  end

  def create
    @user, @account = AccountBuilder.new(
      account_name: account_params[:account_name],
      user_full_name: account_params[:user_full_name],
      email: account_params[:email],
      user_password: account_params[:password],
      locale: account_params[:locale],
      user: current_user
    ).perform
    if @user
      send_auth_headers(@user)
      render 'api/v1/accounts/create', format: :json, locals: { resource: @user }
    else
      render_error_response(CustomExceptions::Account::SignupFailed.new({}))
    end
  end

  def cache_keys
    expires_in 10.seconds, public: false, stale_while_revalidate: 5.minutes
    render json: { cache_keys: cache_keys_for_account }, status: :ok
  end

  def update
    @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email, :type_id, :address, :company_name, :company_address,
                                                    :company_email, :company_tax_id, :id_number))
    @account.custom_attributes = @account.custom_attributes.merge(custom_attributes_params.to_h)
    @account.settings = @account.settings.merge(settings_params.to_h)
    @account.custom_attributes['onboarding_step'] = 'invite_team' if @account.custom_attributes['onboarding_step'] == 'account_update'

    if onboarding_params.to_h.any?
      @account.build_onboarding unless @account.onboarding
      @account.onboarding.assign_attributes(onboarding_params)
    end

    @account.save!
  end

  def update_active_at
    @current_account_user.active_at = Time.now.utc
    @current_account_user.save!
    head :ok
  end

  def test_email
    if params[:email].present?
      TestMailer.with(account: @account).test_email(params[:email]).deliver_now
      head :ok
    else
      render json: { error: 'Email parameter is missing' }, status: :unprocessable_entity
    end
  end

  private

  def ensure_account_name
    # ensure that account_name and user_full_name is present
    # this is becuase the account builder and the models validations are not triggered
    # this change is to align the behaviour with the v2 accounts controller
    # since these values are not required directly there
    return if account_params[:account_name].present?
    return if account_params[:user_full_name].present?

    raise CustomExceptions::Account::InvalidParams.new({})
  end

  def cache_keys_for_account
    {
      label: fetch_value_for_key(params[:id], Label.name.underscore),
      inbox: fetch_value_for_key(params[:id], Inbox.name.underscore),
      team: fetch_value_for_key(params[:id], Team.name.underscore)
    }
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
    Current.account = @account
    Current.account_user = @current_account_user
  end

  def account_params
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :user_full_name, :type_id, :address, :company_name,
                  :company_address, :company_email, :company_tax_id, :id_number)
  end

  def custom_attributes_params
    params.permit(:company_size, :timezone, :source)
  end

  def onboarding_params
    params.permit(:industry, :onboarding_completed, :team_size, :daily_messages, :current_crm, primary_goals: [])
  end

  def settings_params
    params.permit(*permitted_settings_attributes)
  end

  def permitted_settings_attributes
    [
      :auto_resolve_after, :auto_resolve_message, :auto_resolve_ignore_waiting,
      :audio_transcriptions, :auto_resolve_label, :active_ecommerce_platform, :ai_allow_create_order,
      { order_notification_templates: [:confirmed, :processing, :shipped, :delivered, :cancelled] },
      { custom_email_config: [
        :sender_email, :smtp_address, :smtp_port, :smtp_username, :smtp_password,
        :smtp_domain, :smtp_authentication, :smtp_enable_starttls_auto, :smtp_openssl_verify_mode
      ] },
      { sales_payment_config: [
        :default_provider,
        { sepay: [:active, :company_name, :company_code, :secret_key] },
        { payos: [:active, :client_id, :api_key, :checksum_key] }
      ] }
    ]
  end

  def check_signup_enabled
    raise ActionController::RoutingError, 'Not Found' unless GlobalConfigService.account_signup_enabled?
  end

  def validate_captcha
    raise ActionController::InvalidAuthenticityToken, 'Invalid Captcha' unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end

Api::V1::AccountsController.prepend_mod_with('Api::V1::AccountsSettings')
