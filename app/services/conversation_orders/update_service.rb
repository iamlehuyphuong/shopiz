# Service to push an updated ConversationOrder to an external sales platform via API.
# Supports: kiotviet, sapo, haravan, woocommerce, shopify, nhanhvn.
class ConversationOrders::UpdateService
  def initialize(order:, user:)
    @order = order
    @user = user
  end

  def perform
    return { success: false, error: 'Order is not linked to any external platform' } if @order.external_order_id.blank?
    return { success: false, error: 'Platform (external_source) not specified' } if @order.external_source.blank?

    unless ConversationOrders::PlatformRegistry.pushable?(@order.external_source)
      return { success: false, error: "#{@order.external_source} does not support updating orders via API" }
    end

    proxy_class = ConversationOrders::PlatformRegistry.proxy_for(@order.external_source)
    return { success: false, error: "Unsupported platform: #{@order.external_source}" } if proxy_class.nil?

    update_order(proxy_class)
  end

  private

  def update_order(proxy_class)
    client = proxy_class.new(@order.account)
    payload = build_payload
    result = client.update_order(@order.external_order_id, payload)

    error = client.extract_error(result)

    if error.blank?
      send_success_message
      log_activity(:updated)
      { success: true, order: @order }
    else
      { success: false, error: error }
    end
  rescue StandardError => e
    Rails.logger.error("UpdateService error for order #{@order.id}: #{e.message}")
    { success: false, error: "Update failed: #{e.message}" }
  end

  def build_payload
    case @order.external_source
    when 'kiotviet'
      build_kiotviet_payload
    when 'sapo', 'haravan', 'shopify'
      build_shopify_like_payload
    when 'woocommerce'
      build_woocommerce_payload
    when 'nhanhvn'
      build_nhanhvn_payload
    end
  end

  # --- KiotViet ---
  def build_kiotviet_payload
    {
      branchId: kiotviet_branch_id,
      description: @order.customer_note,
      totalPayment: @order.total_amount.to_f,
      orderDetails: @order.items.map do |item|
        {
          productId: item.product_id.to_i,
          productCode: item.product_metadata&.dig('code'),
          quantity: item.quantity,
          price: item.unit_price.to_f
        }
      end,
      customer: {
        name: @order.customer_name,
        contactNumber: @order.customer_phone,
        address: @order.customer_address
      }
    }
  end

  def kiotviet_branch_id
    hook = Integrations::Hook.find_by(account_id: @order.account_id, app_id: 'kiotviet')
    hook&.settings&.dig('branch_id')
  end

  # --- Sapo / Haravan / Shopify ---
  def build_shopify_like_payload
    {
      line_items: @order.items.map do |item|
        { variant_id: item.product_id, quantity: item.quantity, price: item.unit_price.to_f, title: item.product_name }
      end,
      customer: { first_name: @order.customer_name, phone: @order.customer_phone },
      shipping_address: { address1: @order.customer_address, first_name: @order.customer_name, phone: @order.customer_phone },
      note: @order.customer_note
    }
  end

  # --- WooCommerce ---
  def build_woocommerce_payload
    {
      billing: {
        first_name: @order.customer_name,
        phone: @order.customer_phone,
        address_1: @order.customer_address
      },
      line_items: @order.items.map do |item|
        {
          product_id: item.product_id.to_i,
          quantity: item.quantity
        }
      end,
      customer_note: @order.customer_note
    }
  end

  # --- Nhanh.vn ---
  def build_nhanhvn_payload
    {
      customerName: @order.customer_name,
      customerMobile: @order.customer_phone,
      customerAddress: @order.customer_address,
      description: @order.customer_note,
      productList: @order.items.map do |item|
        {
          productId: item.product_id,
          quantity: item.quantity,
          price: item.unit_price.to_f
        }
      end
    }
  end

  def send_success_message
    content = I18n.t(
      'conversation_orders.update_success_message',
      order_id: @order.external_order_id,
      default: "Order updated successfully on external platform! Order ID: #{@order.external_order_id}."
    )

    message_params = {
      content: content,
      message_type: 'outgoing',
      private: false
    }

    Messages::MessageBuilder.new(@user, @order.conversation, message_params).perform
  rescue StandardError => e
    Rails.logger.error("Failed to send order update confirmation message: #{e.message}")
  end

  def log_activity(action_type)
    ConversationOrders::OrderActivityMessageService.new(
      conversation: @order.conversation,
      order: @order,
      action_type: action_type,
      user: @user
    ).perform
  end
end
