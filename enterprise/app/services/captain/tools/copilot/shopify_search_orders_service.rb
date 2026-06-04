class Captain::Tools::Copilot::ShopifySearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::ShopifyClient

  def self.name
    'shopify_search_orders'
  end

  description 'Search Shopify orders by customer email, phone, or get all recent orders'
  param :email, type: :string, desc: 'Customer email to search orders for', required: false
  param :phone, type: :string, desc: 'Customer phone number to search orders for', required: false
  param :status, type: :string, desc: 'Order status filter: any, open, closed, cancelled (default: any)', required: false

  def execute(email: nil, phone: nil, status: 'any')
    return 'Shopify integration is not connected' unless shopify_active?

    orders = resolve_orders(email, phone, status)
    return 'No orders found' if orders.blank?

    total_count = orders.size
    <<~RESPONSE
      #{total_count > 50 ? "Found #{total_count} orders (showing first 50)" : "Found #{total_count} order(s)"}
      #{orders.first(50).map { |o| format_order(o) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def resolve_orders(email, phone, status)
    if email.present? || phone.present?
      customers = search_customers(email, phone)
      return [] if customers.blank?

      fetch_orders(customer_id: customers.first['id'], status: status || 'any')
    else
      fetch_orders(status: status || 'any')
    end
  end

  def search_customers(email, phone)
    query_parts = []
    query_parts << "email:#{email}" if email.present?
    query_parts << "phone:#{phone}" if phone.present?

    result = shopify_get('customers/search.json', { query: query_parts.join(' OR '), fields: 'id,email,phone' })
    result&.dig('customers') || []
  end

  def fetch_orders(filters)
    query = {
      status: 'any',
      fields: 'id,name,email,created_at,total_price,currency,fulfillment_status,financial_status,line_items',
      limit: 50
    }.merge(filters)

    result = shopify_get('orders.json', query)
    result&.dig('orders') || []
  end

  def format_order(order)
    <<~ORDER.strip
      Order #{order['name'] || "##{order['id']}"} | #{format_currency(order['total_price'], order['currency'])}
      Email: #{order['email'] || 'N/A'}
      Payment: #{order['financial_status']} | Fulfillment: #{order['fulfillment_status'] || 'unfulfilled'}
      Date: #{Time.zone.parse(order['created_at']).strftime('%Y-%m-%d %H:%M')}
      Items: #{summarize_items(order['line_items'])}
      Admin: https://#{shopify_hook.reference_id}/admin/orders/#{order['id']}
    ORDER
  end

  def summarize_items(items)
    return 'N/A' if items.blank?

    summary = items.first(3).map { |i| "#{i['title']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items.size - 3} more" if items.size > 3
    summary
  end
end
