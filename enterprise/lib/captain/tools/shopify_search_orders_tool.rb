class Captain::Tools::ShopifySearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::ShopifyClient

  description 'Search Shopify orders for the current contact by matching their email or phone number with Shopify customers'

  def active?
    shopify_active?
  end

  def perform(tool_context)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact
    return 'Contact has no email or phone number to search orders' if contact.email.blank? && contact.phone_number.blank?

    log_tool_usage('shopify_search_orders', { contact_id: contact.id })

    customers = search_customers(contact)
    return 'No matching Shopify customer found' if customers.blank?

    orders = fetch_orders(customers.first['id'])
    return 'No orders found for this customer' if orders.blank?

    format_orders(orders)
  end

  private

  def search_customers(contact)
    query_parts = []
    query_parts << "email:#{contact.email}" if contact.email.present?
    query_parts << "phone:#{contact.phone_number}" if contact.phone_number.present?

    result = shopify_get('customers/search.json', { query: query_parts.join(' OR '), fields: 'id,email,phone' })
    result&.dig('customers') || []
  end

  def fetch_orders(customer_id)
    result = shopify_get('orders.json', {
                           customer_id: customer_id,
                           status: 'any',
                           fields: 'id,name,email,created_at,total_price,currency,fulfillment_status,financial_status,line_items'
                         })
    result&.dig('orders') || []
  end

  def format_orders(orders)
    header = "Found #{orders.size} Shopify order(s):\n\n"
    body = orders.map { |order| format_order(order) }.join("\n---\n")
    header + body
  end

  def format_order(order)
    lines = build_order_lines(order)
    lines << "  Items: #{summarize_items(order['line_items'])}" if order['line_items'].present?
    lines << "  Admin: https://#{shopify_hook.reference_id}/admin/orders/#{order['id']}"
    lines.join("\n")
  end

  def build_order_lines(order)
    [
      "Order #{order['name'] || "##{order['id']}"}",
      "  Total: #{format_currency(order['total_price'], order['currency'])}",
      "  Payment: #{order['financial_status']}",
      "  Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}",
      "  Date: #{Time.zone.parse(order['created_at']).strftime('%Y-%m-%d %H:%M')}"
    ]
  end

  def summarize_items(items)
    summary = items.first(5).map { |i| "#{i['title']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items.size - 5} more" if items.size > 5
    summary
  end
end
