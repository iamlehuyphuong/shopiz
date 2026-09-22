# Public tool: Search Sapo orders for the current contact.
class Captain::Tools::Sapo::SearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Sapo::Client

  description 'Search Sapo orders for the current contact by matching their email or phone with Sapo customers'

  def active?
    sapo_active?
  end

  def perform(tool_context)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact
    return 'Contact has no email or phone to search orders' if contact.email.blank? && contact.phone_number.blank?

    log_tool_usage('sapo_search_orders', { contact_id: contact.id })

    customers = search_customers(contact)
    return 'No matching Sapo customer found' if customers.blank?

    orders = fetch_orders(customers.first['id'])
    return 'No orders found for this customer' if orders.blank?

    format_orders(orders)
  end

  private

  def search_customers(contact)
    query = contact.email.presence || contact.phone_number
    result = sapo_get('customers/search.json', { query: query })
    result&.dig('customers') || []
  end

  def fetch_orders(customer_id)
    result = sapo_get('orders.json', { customer_id: customer_id, status: 'any', limit: 20 })
    result&.dig('orders') || []
  end

  def format_orders(orders)
    header = "Found #{orders.size} Sapo order(s):\n\n"
    body = orders.map { |o| format_order(o) }.join("\n---\n")
    header + body
  end

  def format_order(order)
    lines = [
      "Order #{order['order_number'] || "##{order['id']}"}",
      "  Total: #{format_currency(order['total_price'], order['currency'])}",
      "  Payment: #{order['financial_status']}",
      "  Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}",
      "  Date: #{parse_date(order['created_on'])}"
    ]
    lines << "  Items: #{summarize_items(order['line_items'])}" if order['line_items'].present?
    lines.join("\n")
  end

  def parse_date(date_str)
    return 'N/A' if date_str.blank?

    Time.zone.parse(date_str).strftime('%Y-%m-%d %H:%M')
  end

  def summarize_items(items)
    return 'N/A' if items.blank?

    summary = items.first(5).map { |i| "#{i['name'] || i['title']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items.size - 5} more" if items.size > 5
    summary
  end
end
