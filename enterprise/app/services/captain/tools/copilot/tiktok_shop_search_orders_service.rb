class Captain::Tools::Copilot::TiktokShopSearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TiktokShopClient

  def self.name
    'tiktok_shop_search_orders'
  end

  description 'Search for recent orders on TikTok Shop. If query is a numeric ID, it looks up that order.'
  param :query, type: :string, desc: 'Order ID or keyword to search for'

  def execute(**args)
    arguments = args.stringify_keys
    return 'TikTok Shop integration is not connected.' unless tiktok_shop_active?

    orders = fetch_orders(arguments['query'])
    return 'No orders found.' if orders.blank?

    format_orders(orders)
  end

  def active?
    @user.present? && tiktok_shop_active?
  end

  private

  def fetch_orders(query)
    # If query is mostly digits, it might be an order ID
    if query.present? && query.match?(/^\d+$/)
      result = tiktok_shop_get('/order/202309/orders', { ids: [query] })
      return result&.dig('data', 'orders') || []
    end

    body = { page_size: 10 }
    result = tiktok_shop_post('/order/202309/orders/search', body)
    orders = result&.dig('data', 'orders') || []

    if query.present?
      orders.select { |o| o['id'].to_s.include?(query) }
    else
      orders
    end
  end

  def format_orders(orders)
    orders.first(5).map do |order|
      total = order.dig('payment', 'total_amount').to_f
      currency = order.dig('payment', 'currency') || 'VND'
      status = order['status'] || 'UNKNOWN'

      lines = ["**Order ##{order['id']}** - #{status}"]
      lines << "Total: #{format_tiktok_currency(total, currency)}"
      lines << "Created At: #{Time.zone.at(order['create_time'].to_i).strftime('%Y-%m-%d %H:%M')}" if order['create_time'].present?

      lines.join("\n")
    end.join("\n\n")
  end
end
