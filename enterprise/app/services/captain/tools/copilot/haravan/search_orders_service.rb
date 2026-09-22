# Copilot tool: Search Haravan orders by phone or order name.
class Captain::Tools::Copilot::Haravan::SearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Haravan::Client
  def self.name
    'haravan_search_orders'
  end

  description 'Search Haravan orders by customer phone, email, or order name/number'
  param :query, type: :string, desc: 'Customer phone, email, or order name to search'

  def active?
    haravan_active?
  end

  def execute(**args)
    arguments = args.stringify_keys
    query = arguments['query']
    return 'Query is required' if query.blank?

    orders = search_orders(query)
    return "No Haravan orders found for '#{query}'" if orders.blank?

    format_result(orders, query)
  end

  private

  def search_orders(query)
    result = haravan_get('orders.json', { name: query, status: 'any', limit: 20 })
    orders = result&.dig('orders') || []
    return orders if orders.present?

    customers = search_customers_by_contact(query)
    return [] if customers.blank?

    result = haravan_get('orders.json', { customer_id: customers.first['id'], status: 'any', limit: 20 })
    result&.dig('orders') || []
  end

  def search_customers_by_contact(query)
    result = haravan_get('customers/search.json', { query: query })
    result&.dig('customers') || []
  end

  def format_result(orders, query)
    header = "Found #{orders.size} Haravan order(s) for '#{query}':\n\n"
    body = orders.map { |o| format_order(o) }.join("\n---\n")
    header + body
  end

  def format_order(order)
    [
      "Order #{order['name'] || "##{order['id']}"}",
      "  Customer: #{order.dig('customer', 'first_name')} #{order.dig('customer', 'last_name')}".strip,
      "  Total: #{order['total_price']} #{order['currency']}",
      "  Payment: #{order['financial_status']}",
      "  Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}",
      "  Date: #{order['created_at']}"
    ].join("\n")
  end
end
