# Public tool: Search Nhanh.vn orders for the current contact.
# Searches by contact phone number in Nhanh.vn order database
# using POST /api/order/index with customerMobile param.
class Captain::Tools::Nhanhvn::SearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Nhanhvn::Client

  description 'Search Nhanh.vn orders for the current contact by matching their phone number'

  def active?
    nhanhvn_active?
  end

  def perform(tool_context)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact
    return 'Contact has no phone number to search orders' if contact.phone_number.blank?

    log_tool_usage('nhanhvn_search_orders', { contact_id: contact.id })

    orders = fetch_orders(contact.phone_number)
    return 'No orders found for this customer' if orders.blank?

    format_orders(orders)
  end

  private

  def fetch_orders(phone)
    result = nhanhvn_post('/api/order/index', { customerMobile: phone, icpp: 20 })
    orders_hash = result&.dig('data', 'orders')
    return [] unless orders_hash.is_a?(Hash)

    orders_hash.values
  end

  def format_orders(orders)
    header = "Found #{orders.size} Nhanh.vn order(s):\n\n"
    body = orders.map { |order| format_order(order) }.join("\n---\n")
    header + body
  end

  def format_order(order)
    lines = build_order_lines(order)
    lines << "  Items: #{summarize_items(order['products'])}" if order['products'].present?
    lines.join("\n")
  end

  def build_order_lines(order)
    [
      "Order ##{order['id']}",
      "  Total: #{format_currency(order['calcTotalMoney'])}",
      "  Status: #{order['statusName'] || order['statusCode']}",
      "  Customer: #{order['customerName']} | Phone: #{order['customerMobile']}",
      "  Date: #{order['createdDateTime'] || 'N/A'}",
      "  Carrier: #{order['carrierName'] || 'N/A'}"
    ]
  end

  def summarize_items(items)
    return 'N/A' if items.blank?

    items_array = items.is_a?(Hash) ? items.values : items
    summary = items_array.first(5).map { |i| "#{i['productName']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items_array.size - 5} more" if items_array.size > 5
    summary
  end
end
