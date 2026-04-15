# API controller for managing Zalo OA message templates
# Templates are used for transaction messages and promotion/broadcast messages
class Api::V1::Accounts::ZaloMessageTemplatesController < Api::V1::Accounts::BaseController
  before_action :set_template, only: [:show, :update, :destroy]

  def index
    @templates = Current.account.zalo_message_templates
    @templates = @templates.where(channel_id: params[:channel_id]) if params[:channel_id].present?
    @templates = @templates.by_type(params[:template_type]) if params[:template_type].present?
    render json: @templates
  end

  def show
    render json: @template
  end

  def create
    @template = Current.account.zalo_message_templates.new(template_params)
    if @template.save
      render json: @template, status: :created
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(template_params)
      render json: @template
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy!
    head :no_content
  end

  private

  def set_template
    @template = Current.account.zalo_message_templates.find(params[:id])
  end

  def template_params
    params.permit(:template_name, :template_type, :language, :status, :channel_id, template_content: {})
  end
end
