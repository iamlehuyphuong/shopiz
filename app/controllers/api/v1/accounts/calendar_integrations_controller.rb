class Api::V1::Accounts::CalendarIntegrationsController < Api::V1::Accounts::BaseController
  before_action :fetch_integration, only: [:destroy]

  def index
    @integrations = Current.account.calendar_integrations
  end

  def create
    @integration = Current.account.calendar_integrations.find_or_initialize_by(provider: params[:provider])
    @integration.assign_attributes(integration_params)
    
    if @integration.save
      render json: @integration
    else
      render json: { error: @integration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @integration.destroy
    head :no_content
  end

  private

  def fetch_integration
    @integration = Current.account.calendar_integrations.find(params[:id])
  end

  def integration_params
    params.require(:calendar_integration).permit(
      :access_token,
      :refresh_token,
      :expires_at,
      :email
    )
  end
end
