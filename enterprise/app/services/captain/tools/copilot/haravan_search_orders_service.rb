# Copilot tool: Search Haravan orders by phone or order name.
class Captain::Tools::Copilot::HaravanSearchOrdersService < Captain::Tools::Copilot::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def name
    'haravan_search_orders'
  end

  def description
    'Search Haravan orders by customer phone, email, or order name/number'
  end

  def parameters
    [
      { name: 'query', type: 'string', description: 'Customer phone, email, or order name to search', required: true }
    ]
  end

  def active?
    haravan_active?
  end

  def execute(arguments)
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
