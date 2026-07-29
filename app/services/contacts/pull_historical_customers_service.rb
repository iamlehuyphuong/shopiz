class Contacts::PullHistoricalCustomersService
  pattr_initialize :account_id, :platform, :timeframe

  def perform
    account = Account.find(account_id)
    proxy = ConversationOrders::PlatformRegistry.proxy_for(platform).new(account)
    timeframe_val = parse_timeframe(timeframe)

    customers = fetch_all_customers(proxy, platform, timeframe_val)
    success_count = 0

    customers.each do |raw_customer|
      map_and_save_customer(account, platform, raw_customer)
      success_count += 1
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("PullHistoricalCustomersService error saving customer: #{e.message} - #{e.record.errors.full_messages}")
    rescue StandardError => e
      Rails.logger.error("PullHistoricalCustomersService error saving customer: #{e.message}")
    end

    { success: true, count: success_count }
  end

  private

  def fetch_all_customers(proxy, platform, timeframe_val)
    all_customers = []

    if platform == 'kiotviet'
      page_size = 100
      current_item = 0
      loop do
        result = proxy.fetch_customers(lastModifiedFrom: timeframe_val.iso8601, pageSize: page_size, currentItem: current_item)
        data = result.is_a?(Hash) && result['data'] ? result['data'] : []
        all_customers.concat(data)

        total = result.is_a?(Hash) ? result['total'].to_i : 0
        current_item += page_size
        break if current_item >= total || data.empty?
      end
    elsif platform == 'woocommerce'
      page = 1
      per_page = 100
      loop do
        result = proxy.fetch_customers(after: timeframe_val.iso8601, per_page: per_page, page: page)
        data = result.is_a?(Array) ? result : []
        all_customers.concat(data)

        break if data.length < per_page

        page += 1
      end
    end

    all_customers
  end

  def parse_timeframe(tf)
    case tf.to_s
    when '1_day' then 1.day.ago
    when '1_week' then 1.week.ago
    when '1_month' then 1.month.ago
    else 1.month.ago
    end
  end

  def map_and_save_customer(account, platform, raw_customer)
    if platform == 'kiotviet'
      external_id = raw_customer['id']&.to_s
      return if external_id.blank?

      normalized_phone = normalize_phone_number(raw_customer['contactNumber'])

      contact = account.contacts.find_by(kiotviet_customer_id: external_id)
      contact ||= account.contacts.find_by(phone_number: normalized_phone) if normalized_phone.present?
      contact ||= account.contacts.new(account_id: account.id)

      contact.kiotviet_customer_id = external_id
      contact.name = raw_customer['name'] if contact.name.blank?
      contact.phone_number = normalized_phone if contact.phone_number.blank?
      contact.email = raw_customer['email'] if contact.email.blank?
      contact.location = raw_customer['address'] if contact.location.blank?

      contact.additional_attributes ||= {}
      contact.additional_attributes['kiotviet_code'] = raw_customer['code']
      contact.additional_attributes['kiotviet_debt'] = raw_customer['debt']
      contact.additional_attributes['kiotviet_total_point'] = raw_customer['totalPoint']

      contact.save!
    elsif platform == 'woocommerce'
      external_id = raw_customer['id']&.to_s
      return if external_id.blank?

      contact = account.contacts.find_by(woocommerce_customer_id: external_id)
      contact ||= account.contacts.from_email(raw_customer['email']) if raw_customer['email'].present?

      phone = raw_customer.dig('billing', 'phone')
      normalized_phone = normalize_phone_number(phone)
      contact ||= account.contacts.find_by(phone_number: normalized_phone) if normalized_phone.present?
      contact ||= account.contacts.new(account_id: account.id)

      contact.woocommerce_customer_id = external_id
      name = "#{raw_customer['first_name']} #{raw_customer['last_name']}".strip
      contact.name = name if contact.name.blank?
      contact.email = raw_customer['email'] if contact.email.blank?
      contact.phone_number = normalized_phone if contact.phone_number.blank? && phone.present?
      contact.location = raw_customer.dig('billing', 'address_1') if contact.location.blank?

      contact.save!
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
end
