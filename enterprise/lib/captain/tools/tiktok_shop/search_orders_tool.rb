# Public tool: Search TikTok Shop order by Order ID to check status.
class Captain::Tools::TiktokShop::SearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::TiktokShop::Client

  description 'Look up order details on TikTok Shop by Order ID to provide status, packing, and shipping information to the customer.'
  param :order_id, type: 'string', desc: 'TikTok Shop Order ID provided by the customer', required: true

  def active?
    tiktok_shop_active?
  end

  def perform(_tool_context, order_id:)
    log_tool_usage('tiktok_shop_search_orders', { order_id: order_id })

    order = fetch_order(order_id)
    return "Order ID '#{order_id}' not found on TikTok Shop. Please check if the ID is correct." if order.nil?

    format_order_detail(order)
  end

  private

  def fetch_order(order_id)
    result = tiktok_shop_get('/order/202309/orders', { ids: [order_id] })
    result&.dig('data', 'orders')&.first
  end

  def format_order_detail(order)
    status = order['status'] || 'UNKNOWN'
    total = order.dig('payment', 'total_amount').to_f
    currency = order.dig('payment', 'currency') || 'VND'

    lines = ["📦 **Order ##{order['id']} Detail**"]
    lines << "Status: **#{status}**"
    lines << "Created At: #{Time.zone.at(order['create_time'].to_i).strftime('%Y-%m-%d %H:%M')}" if order['create_time'].present?

    if order['tracking_number'].present?
      lines << "Tracking Number: #{order['tracking_number']}"
      lines << "Shipping Provider: #{order['shipping_provider']}" if order['shipping_provider'].present?
    end

    lines << "\n🛒 **Items:**"
    (order['line_items'] || []).each do |item|
      item_price = item['sale_price'].to_f
      lines << "- #{item['product_name']} x#{item['quantity']}"
      lines << "  SKU: #{item['seller_sku'] || item['sku_id']} | Price: #{format_currency(item_price, currency)}"
    end

    lines << "\n💰 **Total Amount:** #{format_currency(total, currency)}"
    lines.join("\n")
  end
end
