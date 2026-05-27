# Copilot tool: Search Haravan customers by phone, email, or name.
class Captain::Tools::Copilot::HaravanSearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::HaravanClient
  def self.name
    'haravan_search_customers'
  end

  description 'Search Haravan customers by phone number, email address, or name'
  param :query, type: :string, desc: 'Customer phone, email, or name to search'

  def active?
    haravan_active?
  end

  def execute(**args)
    arguments = args.stringify_keys
    query = arguments['query']
    return 'Query is required' if query.blank?

    customers = search_customers(query)
    return "No Haravan customers found for '#{query}'" if customers.blank?

    format_result(customers, query)
  end

  private

  def search_customers(query)
    result = haravan_get('customers/search.json', { query: query })
    result&.dig('customers') || []
  end

  def format_result(customers, query)
    header = "Found #{customers.size} Haravan customer(s) for '#{query}':\n\n"
    body = customers.first(10).map { |c| format_customer(c) }.join("\n---\n")
    header + body
  end

  def format_customer(customer)
    [
      "#{customer['first_name']} #{customer['last_name']}".strip,
      " Email: #{customer['email'] || 'N/A'}",
      " Phone: #{customer['phone'] || 'N/A'}",
      " Orders: #{customer['orders_count'] || 0}",
      " Total Spent: #{customer['total_spent'] || '0'}"
    ].join("\n")
  end
end
