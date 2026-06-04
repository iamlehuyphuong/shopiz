# Service to push a draft ConversationOrder to an external sales platform.
# Supports: kiotviet, sapo, haravan, woocommerce, shopify, nhanhvn.
# TikTok Shop does not support order creation via API.
class ConversationOrders::PushService
  def initialize(order:, user:)
    @order = order
    @user = user
  end

  def perform
    return { success: false, error: 'Order is not in draft status' } unless @order.draft?
    return { success: false, error: 'Platform (external_source) not specified' } if @order.external_source.blank?

    unless ConversationOrders::PlatformRegistry.pushable?(@order.external_source)
      return { success: false, error: "#{@order.external_source} does not support creating orders via API" }
    end

    proxy_class = ConversationOrders::PlatformRegistry.proxy_for(@order.external_source)
    return { success: false, error: "Unsupported platform: #{@order.external_source}" } if proxy_class.nil?

    push_order(proxy_class)
  end

  private

  def push_order(proxy_class)
    client = proxy_class.new(@order.account)
    payload = build_payload
    result = client.create_order(payload)

    external_id = client.extract_order_id(result)

    if external_id.present?
      @order.update!(external_order_id: external_id, status: :confirmed)
      send_success_message
      log_activity(:pushed)
      { success: true, order: @order }
    else
      { success: false, error: client.extract_error(result) }
    end
  rescue StandardError => e
    Rails.logger.error("PushService error for order #{@order.id}: #{e.message}")
    { success: false, error: "Push failed: #{e.message}" }
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
      method: 'Cash',
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

  # --- Sapo / Haravan / Shopify (Shopify-like REST API) ---
  def build_shopify_like_payload
    {
      line_items: @order.items.map do |item|
        { variant_id: item.product_id, quantity: item.quantity, price: item.unit_price.to_f, title: item.product_name }
      end,
      customer: { first_name: @order.customer_name, phone: @order.customer_phone },
      shipping_address: { address1: @order.customer_address, first_name: @order.customer_name, phone: @order.customer_phone },
      note: @order.customer_note,
      financial_status: 'pending'
    }
  end

  # --- WooCommerce ---
  def build_woocommerce_payload
    {
      status: 'pending',
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
      'conversation_orders.push_success_message',
      order_id: @order.external_order_id,
      total: format_currency(@order.total_amount, @order.currency),
      default: "Order confirmed! Order ID: #{@order.external_order_id}. Total: #{format_currency(@order.total_amount, @order.currency)}."
    )

    message_params = {
      content: content,
      message_type: 'outgoing',
      private: false
    }

    Messages::MessageBuilder.new(@user, @order.conversation, message_params).perform
  rescue StandardError => e
    Rails.logger.error("Failed to send order confirmation message: #{e.message}")
  end

  def format_currency(amount, currency = 'VND')
    unit = currency == 'VND' ? 'đ' : currency
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: unit, format: '%n%u', precision: 0)
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
