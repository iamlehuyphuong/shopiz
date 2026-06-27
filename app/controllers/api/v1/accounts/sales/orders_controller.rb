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

  def create
    @order = current_account.conversation_orders.new(order_params)
    auto_fill_customer_info

    if @order.save
      @order.reload
      render json: order_json(@order), status: :created
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def auto_fill_customer_info
    return unless @order.contact

    @order.customer_name ||= @order.contact.name
    @order.customer_phone ||= @order.contact.phone_number
  end

  def order_json(order)
    order.as_json(
      include: {
        contact: { only: [:id, :name, :email, :phone_number] },
        items: {}
      }
    )
  end

  def order_params
    params.require(:order).permit(
      :contact_id, :status, :payment_method, :payment_status,
      :customer_name, :customer_phone, :customer_address, :customer_note,
      :shipping_fee, :tax, :discount_amount, :external_source,
      items_attributes: [:id, :product_id, :product_name, :product_source, :quantity, :unit_price, :product_thumbnail, :_destroy, product_metadata: {}]
    )
  end

  def set_order
    @order = current_account.conversation_orders.find(params[:id])
  end

  def check_authorization
    authorize current_account, :sales_manage?
  end
end
