class Api::V1::Accounts::Integrations::OmicallController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def click_to_call
    sip_info = Current.account.omicall_sip_infos.find_by(user_id: Current.user.id)
    extension = sip_info&.sip_user

    if extension.blank?
      return render json: { error: I18n.t('integrations.omicall.errors.sip_not_configured') || 'OmiCall SIP configuration not found for this user' }, status: :unprocessable_entity
    end

    response = call_service.click2call(
      extension: extension,
      hotline: params[:hotline],
      phone_number: params[:phone_number]
    )

    if response[:error].present?
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: response, status: :ok
    end
  end

  def request_callbot
    response = call_service.request_callbot(
      contacts: params[:contacts],
      sip_numbers: params[:sip_numbers],
      script_id: params[:script_id],
      session_name: params[:session_name],
      voice: params[:voice]
    )

    if response[:error].present?
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: response, status: :ok
    end
  end

  def call_history
    response = call_service.call_history(
      phone_number: params[:phone_number],
      page: params[:page] || 1,
      size: params[:size] || 50
    )

    if response[:error].present?
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: response, status: :ok
    end
  end

  def extensions
    response = call_service.internal_phones

    if response[:error].present?
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: response, status: :ok
    end
  end

  def map_extension
    user = Current.account.users.find_by(id: params[:user_id])
    if user.blank?
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    sip_info = OmicallSipInfo.find_or_initialize_by(account: Current.account, user: user)
    sip_info.sip_user = params[:sip_user]
    sip_info.sip_password = params[:sip_password]
    sip_info.sip_domain = params[:sip_domain]
    sip_info.outbound_proxy = params[:outbound_proxy]

    if sip_info.save
      render json: { message: 'Mapped successfully', sip_info: sip_info }, status: :ok
    else
      render json: { error: sip_info.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def call_service
    @call_service ||= Omicall::CallService.new(Current.account)
  end
end
