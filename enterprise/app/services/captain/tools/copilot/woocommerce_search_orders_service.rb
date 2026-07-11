# Copilot tool: Search WooCommerce orders by email or order ID.
class Captain::Tools::Copilot::WoocommerceSearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient
  def self.name
    'woocommerce_search_orders'
  end

  description 'Search WooCommerce orders by customer email, phone, or order ID'
  param :query, type: :string, desc: 'Customer email, phone, or order ID to search'

  def active?
    woocommerce_active?
  end

  def execute(**args)
    arguments = args.stringify_keys
    query = arguments['query']
    return 'Query is required' if query.blank?

    orders = search_orders(query)
    return "No WooCommerce orders found for '#{query}'" if orders.blank?

    format_result(orders, query)
  end

  private

  def search_orders(query)
    if query.match?(/\A\d+\z/)
      order = woocommerce_get("orders/#{query}")
      return order.is_a?(Hash) && order['id'] ? [order] : []
    end

    result = woocommerce_get('orders', { search: query, per_page: 20, orderby: 'date', order: 'desc' })
    result.is_a?(Array) ? result : []
  end

  def format_result(orders, query)
    header = "Found #{orders.size} WooCommerce order(s) for '#{query}':\n\n"
    body = orders.map { |o| format_order(o) }.join("\n---\n")
    header + body
  end

  def format_order(order)
    billing = order['billing'] || {}
    [
      "Order ##{order['id']}",
      "  Customer: #{billing['first_name']} #{billing['last_name']}".strip,
      "  Email: #{billing['email'] || 'N/A'}",
      "  Total: #{order['total']} #{order['currency']}",
      "  Status: #{order['status']}",
      "  Payment: #{order['payment_method_title'] || 'N/A'}",
      "  Date: #{order['date_created']}"
    ].join("\n")
  end
end
