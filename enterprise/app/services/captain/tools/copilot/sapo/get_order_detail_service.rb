# Copilot tool: Get detailed Sapo order info.
class Captain::Tools::Copilot::Sapo::GetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Sapo::Client

  def self.name
    'sapo_get_order_detail'
  end

  description 'Get detailed information for a specific Sapo order.'
  param :order_id, type: :string, desc: 'Sapo order ID', required: true

  def execute(order_id:)
    return 'Sapo integration is not connected' unless sapo_active?

    order = fetch_order(order_id)
    return "Order '#{order_id}' not found on Sapo" if order.nil?

    format_order_detail(order)
  end

  def active?
    @user.present? && sapo_active?
  end

  private

  def fetch_order(id)
    result = sapo_get("orders/#{id}.json")
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
      "📋 Order ##{order['order_number']} (ID: #{order['id']})",
      "Status: #{order['status']}",
      "Financial: #{order['financial_status']}",
      "Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}",
      "Date: #{order['created_on']}"
    ]
  end

  def build_customer(order)
    customer = order['customer'] || {}
    [
      "\n👤 Customer:",
      "  Name: #{customer['first_name']} #{customer['last_name']}",
      "  Phone: #{customer['phone'] || 'N/A'}",
      "  Email: #{customer['email'] || 'N/A'}"
    ]
  end

  def build_items(order)
    items = order['line_items'] || []
    return ["\n📦 Items: None"] if items.blank?

    lines = ["\n📦 Items (#{items.size}):"]
    items.each { |item| lines << "  • #{item['name']} — #{format_sapo_currency(item['price'])} × #{item['quantity']}" }
    lines
  end

  def build_payment(order)
    [
      "\n💰 Payment:",
      "  Subtotal: #{format_sapo_currency(order['subtotal_price'])}",
      "  Discount: #{format_sapo_currency(order['total_discounts'])}",
      "  Shipping: #{format_sapo_currency(order['total_shipping'])}",
      "  Total: #{format_sapo_currency(order['total_price'])}"
    ]
  end
end
