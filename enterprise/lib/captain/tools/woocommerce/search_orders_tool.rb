# Public tool: Search WooCommerce orders for the current contact.
class Captain::Tools::Woocommerce::SearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Woocommerce::Client

  description 'Search WooCommerce orders for the current contact by matching their email or phone'

  def active?
    woocommerce_active?
  end

  def perform(tool_context)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact
    return 'Contact has no email or phone to search orders' if contact.email.blank? && contact.phone_number.blank?

    log_tool_usage('woocommerce_search_orders', { contact_id: contact.id })

    orders = fetch_orders_for_contact(contact)
    return 'No orders found for this customer' if orders.blank?

    format_orders(orders)
  end

  private

  def fetch_orders_for_contact(contact)
    params = { per_page: 20, orderby: 'date', order: 'desc' }
    params[:search] = contact.email if contact.email.present?
    result = woocommerce_get('orders', params)
    result.is_a?(Array) ? result : []
  end

  def format_orders(orders)
    header = "Found #{orders.size} WooCommerce order(s):\n\n"
    body = orders.map { |o| format_order(o) }.join("\n---\n")
    header + body
  end

  def format_order(order)
    lines = [
      "Order ##{order['id']}",
      "  Total: #{format_woo_currency(order['total'], order['currency'])}",
      "  Status: #{order['status']}",
      "  Payment: #{order['payment_method_title'] || 'N/A'}",
      "  Date: #{parse_date(order['date_created'])}"
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

    summary = items.first(5).map { |i| "#{i['name']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items.size - 5} more" if items.size > 5
    summary
  end
end
