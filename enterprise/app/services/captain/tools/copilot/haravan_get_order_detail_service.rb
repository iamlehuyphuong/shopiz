# Copilot tool: Get detailed Haravan order info.
class Captain::Tools::Copilot::HaravanGetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def self.name
    'haravan_get_order_detail'
  end

  description 'Get detailed information for a specific Haravan order.'
  param :order_id, type: :string, desc: 'Haravan order ID', required: true

  def execute(order_id:)
    return 'Haravan integration is not connected' unless haravan_active?

    order = fetch_order(order_id)
    return "Order '#{order_id}' not found on Haravan" if order.nil?

    format_order_detail(order)
  end

  def active?
    @user.present? && haravan_active?
  end

  private

  def fetch_order(id)
    result = haravan_get("orders/#{id}.json")
    result&.dig('order')
  end

  def format_order_detail(order)
    lines = build_header(order)
    lines.concat(build_customer(order))
    lines.concat(build_items(order))
    lines.concat(build_payment(order))
    lines.join("\n")
  end

  def build_header(order)
    [
      "📋 Order #{order['name'] || "##{order['id']}"}",
      "Financial: #{order['financial_status']}",
      "Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}",
      "Date: #{order['created_at']}"
    ]
  end

  def build_customer(order)
    customer = order['customer'] || {}
    shipping = order['shipping_address'] || {}
    [
      "\n👤 Customer:",
      "  Name: #{customer['first_name']} #{customer['last_name']}",
      "  Phone: #{customer['phone'] || shipping['phone'] || 'N/A'}",
      "  Email: #{customer['email'] || 'N/A'}",
      "  Address: #{shipping['address1'] || 'N/A'}"
    ]
  end

  def build_items(order)
    items = order['line_items'] || []
    return ["\n📦 Items: None"] if items.blank?

    lines = ["\n📦 Items (#{items.size}):"]
    items.each { |item| lines << "  • #{item['title']} — #{format_haravan_currency(item['price'])} × #{item['quantity']}" }
    lines
  end

  def build_payment(order)
    [
      "\n💰 Payment:",
      "  Subtotal: #{format_haravan_currency(order['subtotal_price'])}",
      "  Discount: #{format_haravan_currency(order['total_discounts'])}",
      "  Shipping: #{format_haravan_currency(order['total_shipping_price'])}",
      "  Total: #{format_haravan_currency(order['total_price'])}"
    ]
  end
end
