# Copilot tool: Get detailed WooCommerce order info.
class Captain::Tools::Copilot::WoocommerceGetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient

  def self.name
    'woocommerce_get_order_detail'
  end

  description 'Get detailed information for a specific WooCommerce order.'
  param :order_id, type: :string, desc: 'WooCommerce order ID', required: true

  def execute(order_id:)
    return 'WooCommerce integration is not connected' unless woocommerce_active?

    order = fetch_order(order_id)
    return "Order '#{order_id}' not found" if order.nil?

    format_detail(order)
  end

  def active?
    @user.present? && woocommerce_active?
  end

  private

  def fetch_order(id)
    result = woocommerce_get("orders/#{id}")
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def format_detail(order)
    lines = build_header(order) + build_customer(order) + build_items(order) + build_payment(order)
    lines.join("\n")
  end

  def build_header(order)
    [
      "Order ##{order['number']} (ID: #{order['id']})",
      "Status: #{order['status']}",
      "Payment: #{order['payment_method_title']}",
      "Date: #{order['date_created']}"
    ]
  end

  def build_customer(order)
    billing = order['billing'] || {}
    [
      "\nCustomer:",
      " Name: #{billing['first_name']} #{billing['last_name']}",
      " Phone: #{billing['phone'] || 'N/A'}",
      " Email: #{billing['email'] || 'N/A'}",
      " Address: #{[billing['address_1'], billing['city'], billing['state']].compact.join(', ')}"
    ]
  end

  def build_items(order)
    items = order['line_items'] || []
    return ["\nItems: None"] if items.blank?

    lines = ["\nItems (#{items.size}):"]
    items.each { |i| lines << " • #{i['name']} — #{format_woo_currency(i['price'])} × #{i['quantity']}" }
    lines
  end

  def build_payment(order)
    [
      "\nPayment:",
      " Subtotal: #{format_woo_currency(order['subtotal'])}",
      " Discount: #{format_woo_currency(order['discount_total'])}",
      " Shipping: #{format_woo_currency(order['shipping_total'])}",
      " Total: #{format_woo_currency(order['total'])}"
    ]
  end
end
