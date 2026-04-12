# Copilot tool: Search KiotViet invoices (orders) by customer phone, code, or list recent.
class Captain::Tools::Copilot::KiotvietSearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_search_orders'
  end

  description 'Search KiotViet invoices (orders) by customer phone number, customer code, or list recent invoices'
  param :phone, type: :string, desc: 'Customer phone number to search orders for', required: false
  param :customer_code, type: :string, desc: 'KiotViet customer code to search orders for', required: false

  def execute(phone: nil, customer_code: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    invoices = resolve_invoices(phone, customer_code)
    return 'No orders found' if invoices.blank?

    total_count = invoices.size
    <<~RESPONSE
      #{total_count > 50 ? "Found #{total_count} orders (showing first 50)" : "Found #{total_count} order(s)"}
      #{invoices.first(50).map { |inv| format_invoice(inv) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def resolve_invoices(phone, customer_code)
    customer_id = find_customer_id(phone, customer_code)
    params = { pageSize: 50, orderDirection: 'Desc' }
    params[:customerIds] = customer_id if customer_id.present?

    result = kiotviet_get('invoices', params)
    result&.dig('data') || []
  end

  def find_customer_id(phone, code)
    return nil if phone.blank? && code.blank?

    find_customer_by_code(code) || find_customer_by_phone(phone)
  end

  def find_customer_by_code(code)
    return nil if code.blank?

    result = kiotviet_get("customers/code/#{code}")
    result&.dig('id')
  end

  def find_customer_by_phone(phone)
    return nil if phone.blank?

    result = kiotviet_get('customers', { contactNumber: phone, pageSize: 1 })
    result&.dig('data')&.first&.dig('id')
  end

  def format_invoice(inv)
    <<~INVOICE.strip
      Invoice #{inv['code']} (ID: #{inv['id']}) | #{format_vnd(inv['total'])}
      Customer: #{inv['customerName'] || 'N/A'} | Code: #{inv['customerCode'] || 'N/A'}
      Status: #{resolve_status(inv['status'])} | Payment: #{inv['totalPayment']}/#{inv['total']}
      Date: #{parse_date(inv['createdDate'])}
      Items: #{summarize_items(inv['invoiceDetails'])}
    INVOICE
  end

  def resolve_status(status)
    { 1 => 'Active', 2 => 'Cancelled', 3 => 'Returned' }[status] || "Unknown(#{status})"
  end

  def parse_date(date_str)
    return 'N/A' if date_str.blank?

    Time.zone.parse(date_str).strftime('%Y-%m-%d %H:%M')
  end

  def summarize_items(items)
    return 'N/A' if items.blank?

    summary = items.first(3).map { |i| "#{i['productName']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items.size - 3} more" if items.size > 3
    summary
  end
end
