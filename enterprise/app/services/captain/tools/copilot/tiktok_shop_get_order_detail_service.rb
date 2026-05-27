class Captain::Tools::Copilot::TiktokShopGetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TiktokShopClient

  def self.name
    'tiktok_shop_get_order_detail'
  end

  description 'Get detailed information about a specific TikTok Shop order, including items and tracking status.'
  param :order_id, type: :string, desc: 'TikTok Shop order ID', required: true

  def execute(**args)
    arguments = args.stringify_keys
    return 'TikTok Shop integration is not connected.' unless tiktok_shop_active?

    order_id = arguments['order_id']
    return 'Please provide an order_id.' if order_id.blank?

    order = fetch_order(order_id)
    return "Order ##{order_id} not found." if order.nil?

    format_order_detail(order)
  end

  def active?
    @user.present? && tiktok_shop_active?
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

    lines = ["**Order ##{order['id']} Detail**"]
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
      lines << " SKU: #{item['seller_sku'] || item['sku_id']} | Price: #{format_tiktok_currency(item_price, currency)}"
    end

    lines << "\n**Total Amount:** #{format_tiktok_currency(total, currency)}"
    lines.join("\n")
  end
end
