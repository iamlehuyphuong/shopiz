# Copilot tool: Search Nhanh.vn orders by customer phone, or list recent orders.
class Captain::Tools::Copilot::NhanhvnSearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_search_orders'
  end

  description 'Search Nhanh.vn orders by customer phone number, or list recent orders'
  param :phone, type: :string, desc: 'Customer phone number to search orders for', required: false

  def execute(phone: nil)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    orders = resolve_orders(phone)
    return 'No orders found' if orders.blank?

    total_count = orders.size
    <<~RESPONSE
      #{total_count > 50 ? "Found #{total_count} orders (showing first 50)" : "Found #{total_count} order(s)"}
      #{orders.first(50).map { |order| format_order(order) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def resolve_orders(phone)
    data = { icpp: 50 }
    data[:customerMobile] = phone if phone.present?

    result = nhanhvn_post('/api/order/index', data)
    orders_hash = result&.dig('data', 'orders')
    return [] unless orders_hash.is_a?(Hash)

    orders_hash.values
  end

  def format_order(order)
    <<~ORDER.strip
      Order ##{order['id']} | #{format_vnd(order['calcTotalMoney'])}
      Customer: #{order['customerName'] || 'N/A'} | Phone: #{order['customerMobile'] || 'N/A'}
      Status: #{order['statusName'] || order['statusCode']} | Carrier: #{order['carrierName'] || 'N/A'}
      Date: #{order['createdDateTime'] || 'N/A'}
      Items: #{summarize_items(order['products'])}
    ORDER
  end

  def summarize_items(items)
    return 'N/A' if items.blank?

    items_array = items.is_a?(Hash) ? items.values : items
    summary = items_array.first(3).map { |i| "#{i['productName']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items_array.size - 3} more" if items_array.size > 3
    summary
  end
end
