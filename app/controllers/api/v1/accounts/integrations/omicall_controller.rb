class Api::V1::Accounts::Integrations::OmicallController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def click_to_call
    response = call_service.click2call(
      extension: params[:extension],
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

  def extensions
    response = call_service.internal_phones(
      page: params[:page] || 1,
      size: params[:size] || 100
    )

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

    custom_attributes = user.custom_attributes || {}
    custom_attributes['sip_user'] = params[:sip_user]
    custom_attributes['sip_password'] = params[:sip_password]
    custom_attributes['sip_domain'] = params[:sip_domain]

    if user.update(custom_attributes: custom_attributes)
      render json: { message: 'Mapped successfully', user: user.slice(:id, :name, :email, :custom_attributes) }, status: :ok
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def call_service
    @call_service ||= Omicall::CallService.new(Current.account)
  end

  def check_authorization
    authorize! :manage, Integrations::Hook
  end
end
