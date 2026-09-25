# Public tool: Search KiotViet invoices (orders) for the current contact.
# Searches by contact phone number or email in KiotViet customer database,
# then fetches their invoices (= completed sales).
class Captain::Tools::Kiotviet::SearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Kiotviet::Client

  description 'Search KiotViet invoices (orders) for the current contact by matching their phone or email with KiotViet customers'

  def active?
    kiotviet_active?
  end

  def perform(tool_context)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact
    return 'Contact has no email or phone to search orders' if contact.email.blank? && contact.phone_number.blank?

    log_tool_usage('kiotviet_search_orders', { contact_id: contact.id })

    customer = find_kiotviet_customer(contact)
    return 'No matching KiotViet customer found' if customer.nil?

    invoices = fetch_invoices(customer['id'])
    return 'No orders found for this customer' if invoices.blank?

    format_invoices(invoices)
  end

  private

  def find_kiotviet_customer(contact)
    cached_id = get_external_customer_id(contact, 'kiotviet')
    return { 'id' => cached_id } if cached_id.present?

    customer = search_by_phone(contact.phone_number) if contact.phone_number.present?
    customer ||= search_by_email(contact.email) if contact.email.present?
    customer ||= search_by_name(contact.name) if contact.name.present?

    save_external_customer_id(contact, 'kiotviet', customer['id']) if customer.present?

    customer
  end

  def search_by_phone(phone)
    result = kiotviet_get('customers', { contactNumber: phone, pageSize: 1 })
    result&.dig('data')&.first
  end

  def search_by_name(name)
    result = kiotviet_get('customers', { name: name, pageSize: 1 })
    result&.dig('data')&.first
  end

  def search_by_email(email)
    result = kiotviet_get('customers', { email: email, pageSize: 1 })
    result&.dig('data')&.first
  end

  def fetch_invoices(customer_id)
    result = kiotviet_get('invoices', { customerIds: customer_id, pageSize: 20, orderDirection: 'Desc' })
    result&.dig('data') || []
  end

  def format_invoices(invoices)
    header = "Found #{invoices.size} KiotViet order(s):\n\n"
    body = invoices.map { |inv| format_invoice(inv) }.join("\n---\n")
    header + body
  end

  def format_invoice(inv)
    lines = build_invoice_lines(inv)
    lines << "  Items: #{summarize_items(inv['invoiceDetails'])}" if inv['invoiceDetails'].present?
    lines.join("\n")
  end

  def build_invoice_lines(inv)
    [
      "Invoice #{inv['code']} (ID: #{inv['id']})",
      "  Total: #{format_currency(inv['total'])}",
      "  Status: #{resolve_status(inv['status'])}",
      "  Payment: #{inv['totalPayment']} / #{inv['total']}",
      "  Date: #{parse_date(inv['createdDate'])}"
    ]
  end

  def resolve_status(status)
    case status
    when 1 then 'Active'
    when 2 then 'Cancelled'
    when 3 then 'Returned'
    else "Unknown(#{status})"
    end
  end

  def parse_date(date_str)
    return 'N/A' if date_str.blank?

    Time.zone.parse(date_str).strftime('%Y-%m-%d %H:%M')
  end

  def summarize_items(items)
    return 'N/A' if items.blank?

    summary = items.first(5).map { |i| "#{i['productName']} x#{i['quantity']}" }.join(', ')
    summary += ", +#{items.size - 5} more" if items.size > 5
    summary
  end
end
