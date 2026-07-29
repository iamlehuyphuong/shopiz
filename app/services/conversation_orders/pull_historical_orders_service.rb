class ConversationOrders::PullHistoricalOrdersService
  pattr_initialize :account_id, :platform, :timeframe

  def perform
    account = Account.find(account_id)
    proxy = ConversationOrders::PlatformRegistry.proxy_for(platform).new(account)
    timeframe_val = parse_timeframe(timeframe)

    orders = fetch_all_orders(proxy, platform, timeframe_val)
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

  def fetch_all_orders(proxy, platform, timeframe_val)
    all_orders = []

    if platform == 'kiotviet'
      page_size = 100
      current_item = 0
      loop do
        result = proxy.fetch_orders(lastModifiedFrom: timeframe_val.iso8601, pageSize: page_size, currentItem: current_item)
        data = result.is_a?(Hash) && result['data'] ? result['data'] : []
        all_orders.concat(data)

        total = result.is_a?(Hash) ? result['total'].to_i : 0
        current_item += page_size
        break if current_item >= total || data.empty?
      end
    elsif platform == 'woocommerce'
      page = 1
      per_page = 100
      loop do
        result = proxy.fetch_orders(after: timeframe_val.iso8601, per_page: per_page, page: page)
        data = result.is_a?(Array) ? result : []
        all_orders.concat(data)

        break if data.length < per_page

        page += 1
      end
    end

    all_orders
  end

  def parse_timeframe(tf)
    case tf.to_s
    when '1_day' then 1.day.ago
    when '1_week' then 1.week.ago
    when '1_month' then 1.month.ago
    else 1.month.ago
    end
  end

  def resolve_contact(account, platform, raw_order)
    if platform == 'kiotviet'
      customer_id = raw_order['customerId']&.to_s
      return account.contacts.find_by(kiotviet_customer_id: customer_id) if customer_id.present?

      phone = raw_order.dig('orderDelivery', 'contactNumber')
      normalized_phone = normalize_phone_number(phone)
      return account.contacts.find_by(phone_number: normalized_phone) if normalized_phone.present?

      name = raw_order['customerName']
      if name.present?
        contact = account.contacts.find_or_create_by!(name: name, phone_number: normalized_phone, account_id: account.id)
        contact.update(location: raw_order.dig('orderDelivery', 'address')) if raw_order.dig('orderDelivery', 'address').present?
        return contact
      end
    elsif platform == 'woocommerce'
      customer_id = raw_order['customer_id']&.to_s
      customer_id = nil if customer_id == '0'
      return account.contacts.find_by(woocommerce_customer_id: customer_id) if customer_id.present?

      email = raw_order.dig('billing', 'email')
      return account.contacts.from_email(email) if email.present?

      phone = raw_order.dig('billing', 'phone')
      normalized_phone = normalize_phone_number(phone)
      return account.contacts.find_by(phone_number: normalized_phone) if normalized_phone.present?

      name = "#{raw_order.dig('billing', 'first_name')} #{raw_order.dig('billing', 'last_name')}".strip
      if name.present?
        contact = account.contacts.find_or_create_by!(name: name, email: email, phone_number: normalized_phone, account_id: account.id)
        address = [raw_order.dig('billing', 'address_1'), raw_order.dig('billing', 'city'), raw_order.dig('billing', 'country')].compact_blank.join(', ')
        contact.update(location: address) if address.present?
        return contact
      end
    end

    nil
  end

  def upsert_items(order, proxy, platform, raw_order)
    items_data = proxy.extract_line_items(raw_order)
    return if items_data.blank?

    items_data.each do |item_data|
      item = order.items.find_or_initialize_by(external_id: item_data[:external_id])
      item.assign_attributes(item_data.except(:external_id))
      item.save!
    end
  end

  def normalize_phone_number(phone)
    return nil if phone.blank?

    phone_str = phone.to_s.gsub(/[^\d\+]/, '')
    return nil if phone_str.blank?

    if phone_str.start_with?('0')
      "+84#{phone_str[1..-1]}"
    elsif phone_str.start_with?('84')
      "+#{phone_str}"
    elsif phone_str.start_with?('+')
      phone_str
    else
      "+84#{phone_str}"
    end
  end

  def map_and_save_order(account, proxy, platform, raw_order)
    external_order_id = proxy.extract_order_id(raw_order)
    return if external_order_id.blank?

    order = account.conversation_orders.find_or_initialize_by(
      external_source: platform,
      external_order_id: external_order_id
    )

    contact = resolve_contact(account, platform, raw_order)
    order.contact_id = contact&.id

    if platform == 'kiotviet'
      order.customer_name = raw_order['customerName']
      order.customer_phone = normalize_phone_number(raw_order.dig('orderDelivery', 'contactNumber'))
      order.customer_address = raw_order.dig('orderDelivery', 'address')
      order.status = proxy.map_status(raw_order['status']) || :draft
      order.total_amount = raw_order['total'] || 0
      order.discount_amount = raw_order['discount'] || 0
      order.tax = raw_order['totalTax'] || 0
      order.shipping_fee = raw_order.dig('orderDelivery', 'price') || 0

      existing_items = order.items.index_by(&:product_name)
      (raw_order['orderDetails'] || []).each do |detail|
        product_name = detail['productName']
        item = existing_items.delete(product_name) || order.items.build(product_name: product_name)
        
        product_code = detail['productCode']
        if product_code.present?
          product = account.products.find_by(sku: product_code)
          item.product_id = product.id if product
        end

        item.quantity = detail['quantity'] || 1
        item.unit_price = detail['price'] || 0
      end
      existing_items.values.each(&:mark_for_destruction)

    elsif platform == 'woocommerce'
      billing = raw_order['billing'] || {}
      order.customer_name = "#{billing['first_name']} #{billing['last_name']}".strip
      order.customer_phone = normalize_phone_number(billing['phone'])
      order.customer_email = billing['email']
      order.customer_address = [billing['address_1'], billing['city'], billing['country']].compact_blank.join(', ')
      order.status = proxy.map_status(raw_order['status']) || :draft
      order.total_amount = raw_order['total'] || 0
      order.discount_amount = raw_order['discount_total'] || 0
      order.shipping_fee = raw_order['shipping_total'] || 0
      order.tax = raw_order['total_tax'] || 0

      existing_items = order.items.index_by(&:product_name)
      (raw_order['line_items'] || []).each do |li|
        product_name = li['name']
        item = existing_items.delete(product_name) || order.items.build(product_name: product_name)
        
        sku = li['sku']
        if sku.present?
          product = account.products.find_by(sku: sku)
          item.product_id = product.id if product
        end

        item.quantity = li['quantity'] || 1
        item.unit_price = li['price'] || 0
      end
      existing_items.values.each(&:mark_for_destruction)
    end

    order.last_synced_at = Time.current
    order.save!
  end
end
