# Copilot tool: Search WooCommerce customers by email, name, or phone.
class Captain::Tools::Copilot::WoocommerceSearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient
  def self.name
    'woocommerce_search_customers'
  end

  description 'Search WooCommerce customers by email, name, or phone number'
  param :query, type: :string, desc: 'Customer email, name, or phone to search'

  def active?
    woocommerce_active?
  end

  def execute(**args)
    arguments = args.stringify_keys
    query = arguments['query']
    return 'Query is required' if query.blank?

    customers = search_customers(query)
    return "No WooCommerce customers found for '#{query}'" if customers.blank?

    format_result(customers, query)
  end

  private

  def search_customers(query)
    result = woocommerce_get('customers', { search: query, per_page: 20 })
    result.is_a?(Array) ? result : []
  end

  def format_result(customers, query)
    header = "Found #{customers.size} WooCommerce customer(s) for '#{query}':\n\n"
    body = customers.first(10).map { |c| format_customer(c) }.join("\n---\n")
    header + body
  end

  def format_customer(customer)
    billing = customer['billing'] || {}
    [
      "#{customer['first_name']} #{customer['last_name']}".strip,
      " Email: #{customer['email'] || 'N/A'}",
      " Phone: #{billing['phone'] || 'N/A'}",
      " Orders: #{customer['orders_count'] || 0}",
      " Total Spent: #{customer['total_spent'] || '0'}"
    ].join("\n")
  end
end
