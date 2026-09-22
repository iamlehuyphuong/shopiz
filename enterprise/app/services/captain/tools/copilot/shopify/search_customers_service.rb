class Captain::Tools::Copilot::Shopify::SearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Shopify::Client

  def self.name
    'shopify_search_customers'
  end

  description 'Search Shopify customers by email, phone, or name'
  param :query, type: :string, desc: 'Search query - can be email, phone number, or customer name', required: true

  def execute(query:)
    return 'Shopify integration is not connected' unless shopify_active?

    customers = search_customers(query)
    return "No Shopify customers found matching '#{query}'" if customers.blank?

    <<~RESPONSE
      Found #{customers.size} Shopify customer(s) matching '#{query}':
      #{customers.first(20).map { |c| format_customer(c) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def search_customers(query)
    result = shopify_get('customers/search.json', {
                           query: query,
                           fields: 'id,email,phone,first_name,last_name,orders_count,total_spent,created_at,note',
                           limit: 20
                         })
    result&.dig('customers') || []
  end

  def format_customer(customer)
    lines = build_customer_lines(customer)
    lines << "Note: #{customer['note'].truncate(200)}" if customer['note'].present?
    lines.join("\n")
  end

  def build_customer_lines(customer)
    name = [customer['first_name'], customer['last_name']].compact.join(' ')
    since = customer['created_at'] ? Time.zone.parse(customer['created_at']).strftime('%Y-%m-%d') : 'N/A'

    [
      "#{name.presence || 'Unknown'} (ID: #{customer['id']})",
      "Email: #{customer['email'] || 'N/A'} | Phone: #{customer['phone'] || 'N/A'}",
      "Orders: #{customer['orders_count'] || 0} | Total Spent: #{customer['total_spent'] || '0.00'}",
      "Since: #{since}"
    ]
  end
end
