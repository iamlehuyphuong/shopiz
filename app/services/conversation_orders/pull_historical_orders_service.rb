class ConversationOrders::PullHistoricalOrdersService
  pattr_initialize :account_id, :platform, :timeframe

  def perform
    account = Account.find(account_id)
    proxy = ConversationOrders::PlatformRegistry.proxy_for(platform).new(account)

    timeframe_val = parse_timeframe(timeframe)

    if platform == 'kiotviet'
      result = proxy.fetch_orders(lastModifiedFrom: timeframe_val.iso8601, pageSize: 100)
      orders = result.is_a?(Hash) && result['data'] ? result['data'] : []
    elsif platform == 'woocommerce'
      orders = proxy.fetch_orders(after: timeframe_val.iso8601, per_page: 100)
      orders = [] unless orders.is_a?(Array)
    else
      orders = []
    end

    success_count = 0
    orders.each do |raw_order|
      map_and_save_order(account, proxy, platform, raw_order)
      success_count += 1
    rescue StandardError => e
      Rails.logger.error("PullHistoricalOrdersService error saving order: #{e.message}")
    end

    { success: true, count: success_count }
  end

  private

  def parse_timeframe(tf)
    case tf.to_s
    when '1_day' then 1.day.ago
    when '1_week' then 1.week.ago
    when '1_month' then 1.month.ago
    else 1.month.ago
    end
  end

  def map_and_save_order(account, proxy, platform, raw_order)
    external_order_id = proxy.extract_order_id(raw_order)
    return if external_order_id.blank?

    order = account.conversation_orders.find_or_initialize_by(
      external_source: platform,
      external_order_id: external_order_id
    )

    if platform == 'kiotviet'
      order.customer_name = raw_order['customerName']
      order.customer_phone = raw_order.dig('orderDelivery', 'contactNumber')
      order.status = proxy.map_status(raw_order['status']) || :draft
      order.total_amount = raw_order['total'] || 0
      order.discount_amount = raw_order['discount'] || 0
      order.tax = raw_order['totalTax'] || 0
      order.shipping_fee = raw_order.dig('orderDelivery', 'price') || 0

      order.items.destroy_all if order.persisted?
      (raw_order['orderDetails'] || []).each do |detail|
        order.items.build(
          product_name: detail['productName'],
          quantity: detail['quantity'] || 1,
          unit_price: detail['price'] || 0
        )
      end

    elsif platform == 'woocommerce'
      billing = raw_order['billing'] || {}
      order.customer_name = "#{billing['first_name']} #{billing['last_name']}".strip
      order.customer_phone = billing['phone']
      order.status = proxy.map_status(raw_order['status']) || :draft
      order.total_amount = raw_order['total'] || 0
      order.discount_amount = raw_order['discount_total'] || 0
      order.shipping_fee = raw_order['shipping_total'] || 0
      order.tax = raw_order['total_tax'] || 0

      order.items.destroy_all if order.persisted?
      (raw_order['line_items'] || []).each do |item|
        order.items.build(
          product_name: item['name'],
          quantity: item['quantity'] || 1,
          unit_price: item['price'] || 0
        )
      end
    end

    order.last_synced_at = Time.current
    order.save!
  end
end
