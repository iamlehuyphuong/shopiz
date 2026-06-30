class Api::V1::Accounts::Conversations::OrdersController < Api::V1::Accounts::Conversations::BaseController
  before_action :set_order, only: [:show, :update, :destroy, :push, :sync]
  before_action :check_sales_permission, only: [:create, :update, :destroy, :push]

  def index
    conversation_orders = @conversation.conversation_orders.ordered.includes(:items)
    contact_orders = fetch_contact_orders

    render json: {
      conversation_orders: conversation_orders.map { |order| order_json(order) },
      contact_orders: contact_orders.map { |order| order_json(order) }
    }
  end

  def show
    render json: order_json(@order)
  end

  def create
    @order = @conversation.conversation_orders.new(order_params)
    @order.account = Current.account
    @order.contact = @conversation.contact
    auto_fill_customer_info

    if @order.save
      @order.reload
      log_order_activity(@order, :created)
      render json: order_json(@order), status: :created
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
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
    log_order_activity(@order, :deleted)
    @order.destroy!
    head :ok
  end

  def push
    result = ConversationOrders::PushService.new(order: @order, user: current_user).perform
    if result[:success]
      render json: order_json(@order.reload)
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    end
  end

  def sync
    result = ConversationOrders::SyncService.new(order: @order, user: current_user).perform
    if result[:success]
      render json: order_json(@order.reload)
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = @conversation.conversation_orders.find(params[:id])
  end

  def check_sales_permission
    account_user = Current.account_user
    return if account_user&.administrator?
    return unless account_user&.custom_role_id.present?
    return if account_user.custom_role&.permissions&.include?('sales_manage')

    render json: { error: 'You do not have permission to manage orders' }, status: :forbidden
  end

  def log_order_activity(order, action_type)
    ConversationOrders::OrderActivityMessageService.new(
      conversation: @conversation,
      order: order,
      action_type: action_type,
      user: current_user
    ).perform
  end

  def order_params
    params.permit(
      :status, :customer_name, :customer_phone, :customer_address,
      :customer_note, :currency, :external_order_id, :external_source,
      :shipping_fee, :tax, :discount_amount, :shipping_carrier,
      :tracking_code, :payment_method, :payment_status,
      items_attributes: [
        :id, :product_name, :product_id, :product_source, :quantity,
        :unit_price, :product_thumbnail, :variant_id, :_destroy,
        product_metadata: {}
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

  def fetch_contact_orders
    contact = @conversation.contact
    return [] unless contact

    ConversationOrder
      .where(contact_id: contact.id)
      .where.not(conversation_id: @conversation.id)
      .ordered.includes(:items).limit(20)
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
      shipping_fee: order.shipping_fee.to_f,
      tax: order.tax.to_f,
      discount_amount: order.discount_amount.to_f,
      shipping_carrier: order.shipping_carrier,
      tracking_code: order.tracking_code,
      payment_method: order.payment_method,
      payment_status: order.payment_status,
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
      variant_id: item.variant_id,
      product_source: item.product_source,
      quantity: item.quantity,
      unit_price: item.unit_price.to_f,
      total_price: item.total_price.to_f,
      product_thumbnail: item.product_thumbnail,
      product_metadata: item.product_metadata
    }
  end
end
