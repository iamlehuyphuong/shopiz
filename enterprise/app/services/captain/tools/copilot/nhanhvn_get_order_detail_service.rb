# Copilot tool: Get detailed information for a specific Nhanh.vn order.
class Captain::Tools::Copilot::NhanhvnGetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_get_order_detail'
  end

  description 'Get detailed information for a specific Nhanh.vn order by ID, ' \
              'including items, payment, shipping status, and customer info.'
  param :order_id, type: :string, desc: 'Nhanh.vn order ID to look up', required: true

  def execute(order_id:)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    order = fetch_order(order_id)
    return "Order '#{order_id}' not found on Nhanh.vn" if order.nil?

    format_order_detail(order)
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def fetch_order(order_id)
    result = nhanhvn_post('/api/order/index', { id: order_id, icpp: 1 })
    orders_hash = result&.dig('data', 'orders')
    return nil unless orders_hash.is_a?(Hash)

    orders_hash.values.first
  end

  def format_order_detail(order)
    lines = build_header_lines(order)
    lines.concat(build_customer_lines(order))
    lines.concat(build_items_lines(order))
    lines.concat(build_payment_lines(order))
    lines.concat(build_shipping_lines(order))
    lines.join("\n")
  end

  def build_header_lines(order)
    [
      "📋 Order ##{order['id']}",
      "Status: #{order['statusName'] || order['statusCode']}",
      "Type: #{order['type'] || 'N/A'}",
      "Date: #{order['createdDateTime'] || 'N/A'}"
    ]
  end

  def build_customer_lines(order)
    [
      "\n👤 Customer:",
      "  Name: #{order['customerName'] || 'N/A'}",
      "  Phone: #{order['customerMobile'] || 'N/A'}",
      "  Email: #{order['customerEmail'] || 'N/A'}",
      "  Address: #{order['customerAddress'] || 'N/A'}"
    ]
  end

  def build_items_lines(order)
    items = extract_items(order)
    return ["\n📦 Items: None"] if items.blank?

    lines = ["\n📦 Items (#{items.size}):"]
    items.each do |item|
      lines << "  • #{item['productName']} — #{format_vnd(item['price'])} × #{item['quantity']}"
    end
    lines
  end

  def extract_items(order)
    products = order['products']
    return [] if products.blank?

    products.is_a?(Hash) ? products.values : products
  end

  def build_payment_lines(order)
    [
      "\n💰 Payment:",
      "  Subtotal: #{format_vnd(order['calcTotalMoney'])}",
      "  Discount: #{format_vnd(order['moneyDiscount'])}",
      "  Ship Fee: #{format_vnd(order['customerShipFee'])}",
      "  Deposit: #{format_vnd(order['moneyDeposit'])}",
      "  Transfer: #{format_vnd(order['moneyTransfer'])}"
    ]
  end

  def build_shipping_lines(order)
    [
      "\n🚚 Shipping:",
      "  Carrier: #{order['carrierName'] || 'N/A'}",
      "  Tracking: #{order['carrierCode'] || 'N/A'}",
      "  Weight: #{order['weight'] || 'N/A'}g",
      "  Note: #{order['description'] || 'N/A'}"
    ]
  end
end
