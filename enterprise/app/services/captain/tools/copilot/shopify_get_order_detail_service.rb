# Copilot tool: Get detailed Shopify order info.
class Captain::Tools::Copilot::ShopifyGetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::ShopifyClient

  def self.name
    'shopify_get_order_detail'
  end

  description 'Get detailed information for a specific Shopify order.'
  param :order_id, type: :string, desc: 'Shopify order ID', required: true

  def execute(order_id:)
    return 'Shopify integration is not connected' unless shopify_active?

    order = fetch_order(order_id)
    return "Order '#{order_id}' not found" if order.nil?

    format_detail(order)
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def fetch_order(id)
    result = shopify_get("orders/#{id}.json")
    result&.dig('order')
  end

  def format_detail(order)
    lines = build_header(order) + build_customer(order) + build_items(order) + build_payment(order)
    lines.join("\n")
  end

  def build_header(order)
    [
      "Order #{order['name'] || "##{order['id']}"}",
      "Financial: #{order['financial_status']}",
      "Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}",
      "Date: #{order['created_at']}"
    ]
  end

  def build_customer(order)
    customer = order['customer'] || {}
    [
      "\nCustomer:",
      " Name: #{customer['first_name']} #{customer['last_name']}",
      " Phone: #{customer['phone'] || 'N/A'}",
      " Email: #{customer['email'] || 'N/A'}"
    ]
  end

  def build_items(order)
    items = order['line_items'] || []
    return ["\nItems: None"] if items.blank?

    lines = ["\nItems (#{items.size}):"]
    items.each { |i| lines << " • #{i['title']} — #{format_currency(i['price'], order['currency'])} × #{i['quantity']}" }
    lines
  end

  def build_payment(order)
    [
      "\nPayment:",
      " Subtotal: #{format_currency(order['subtotal_price'], order['currency'])}",
      " Discount: #{format_currency(order['total_discounts'], order['currency'])}",
      " Total: #{format_currency(order['total_price'], order['currency'])}"
    ]
  end
end
