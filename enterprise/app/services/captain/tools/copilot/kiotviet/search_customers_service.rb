# Copilot tool: Search KiotViet customers by phone, name, or code.
class Captain::Tools::Copilot::Kiotviet::SearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Kiotviet::Client

  def self.name
    'kiotviet_search_customers'
  end

  description 'Search KiotViet customers by phone number, name, or customer code'
  param :query, type: :string, desc: 'Search query - can be phone number, customer name, or code', required: true

  def execute(query:)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    customers = search_customers(query)
    return "No KiotViet customers found matching '#{query}'" if customers.blank?

    <<~RESPONSE
      Found #{customers.size} KiotViet customer(s) matching '#{query}':
      #{customers.first(20).map { |c| format_customer(c) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def search_customers(query)
    results = search_by_phone(query)
    results = search_by_name(query) if results.blank?
    results
  end

  def search_by_phone(query)
    result = kiotviet_get('customers', { contactNumber: query, pageSize: 20 })
    result&.dig('data') || []
  end

  def search_by_name(query)
    result = kiotviet_get('customers', { name: query, pageSize: 20 })
    result&.dig('data') || []
  end

  def format_customer(customer)
    lines = build_customer_lines(customer)
    lines << "Address: #{customer['address'].truncate(200)}" if customer['address'].present?
    lines.join("\n")
  end

  def build_customer_lines(customer)
    since = customer['createdDate'] ? Time.zone.parse(customer['createdDate']).strftime('%Y-%m-%d') : 'N/A'

    [
      "#{customer['name'] || 'Unknown'} (Code: #{customer['code']})",
      "Phone: #{customer['contactNumber'] || 'N/A'} | Email: #{customer['email'] || 'N/A'}",
      "Debt: #{format_vnd(customer['debt'])} | Total Revenue: #{format_vnd(customer['totalRevenue'])}",
      "Since: #{since}"
    ]
  end
end
