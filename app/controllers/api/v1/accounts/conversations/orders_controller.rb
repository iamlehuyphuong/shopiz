class Api::V1::Accounts::Conversations::OrdersController < Api::V1::Accounts::Conversations::BaseController
  before_action :set_order, only: [:show, :update, :destroy]

  def index
    @orders = @conversation.conversation_orders.ordered.includes(:items)
    render json: @orders.map { |order| order_json(order) }
  end

  def create
    @order = @conversation.conversation_orders.new(order_params)
    @order.account = Current.account
    @order.contact = @conversation.contact
    auto_fill_customer_info

    if @order.save
      @order.reload
      render json: order_json(@order), status: :created
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render json: order_json(@order)
  end

  def update
    if @order.update(order_params)
      @order.reload
      render json: order_json(@order)
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy!
    head :ok
  end

  private

  def set_order
    @order = @conversation.conversation_orders.find(params[:id])
  end

  def order_params
    params.permit(
      :status, :customer_name, :customer_phone, :customer_address,
      :customer_note, :currency, :external_order_id, :external_source,
      items_attributes: [
        :id, :product_name, :product_id, :product_source, :quantity,
        :unit_price, :product_thumbnail, :product_metadata, :_destroy
      ]
    )
  end

  def auto_fill_customer_info
    contact = @conversation.contact
    return unless contact

    @order.customer_name ||= contact.name
    @order.customer_phone ||= contact.phone_number
    @order.customer_address ||= contact.additional_attributes&.dig('address')
  end

  def order_json(order)
    {
      id: order.id,
      status: order.status,
      customer_name: order.customer_name,
      customer_phone: order.customer_phone,
      customer_address: order.customer_address,
      customer_note: order.customer_note,
      total_amount: order.total_amount.to_f,
      currency: order.currency,
      external_order_id: order.external_order_id,
      external_source: order.external_source,
      created_at: order.created_at,
      updated_at: order.updated_at,
      items: order.items.map { |item| item_json(item) }
    }
  end

  def item_json(item)
    {
      id: item.id,
      product_name: item.product_name,
      product_id: item.product_id,
      product_source: item.product_source,
      quantity: item.quantity,
      unit_price: item.unit_price.to_f,
      total_price: item.total_price.to_f,
      product_thumbnail: item.product_thumbnail,
      product_metadata: item.product_metadata
    }
  end
end
