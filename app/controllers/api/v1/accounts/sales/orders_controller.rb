class Api::V1::Accounts::Sales::OrdersController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_order, only: [:show]

  def index
    @orders = current_account.conversation_orders.includes(:contact, :items).order(created_at: :desc)
    render json: @orders.as_json(
      include: {
        contact: { only: [:id, :name, :email, :phone_number] },
        items: { only: [:id, :product_name, :quantity, :unit_price] }
      }
    )
  end

  def show
    render json: @order.as_json(
      include: {
        contact: { only: [:id, :name, :email, :phone_number] },
        items: {}
      }
    )
  end

  private

  def set_order
    @order = current_account.conversation_orders.find(params[:id])
  end

  def check_authorization
    authorize current_account, :sales_manage?
  end
end
