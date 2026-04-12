class Captain::Tools::Copilot::SapoSearchCustomersService < Captain::Tools::Copilot::BaseService
  include Captain::Tools::Concerns::SapoClient

  def tool_name
    'sapo_search_customers'
  end

  def tool_description
    'Search for customers on the Sapo store by name, email, or phone.'
  end

  def tool_parameters
    [
      { name: 'query', type: 'string', description: 'Customer name, email, or phone to search' }
    ]
  end

  def execute(arguments)
    return 'Sapo integration is not connected.' unless sapo_active?

    customers = fetch_customers(arguments['query'])
    return 'No customers found.' if customers.blank?

    format_customers(customers)
  end

  private

  def fetch_customers(query)
    params = { limit: 10 }
    params[:query] = query if query.present?
    endpoint = query.present? ? 'customers/search.json' : 'customers.json'
    result = sapo_get(endpoint, params)
    result&.dig('customers') || []
  end

  def format_customers(customers)
    customers.map do |c|
      "**#{c['first_name']} #{c['last_name']}** (ID: #{c['id']})\n  " \
        "Email: #{c['email'] || 'N/A'}\n  " \
        "Phone: #{c['phone'] || 'N/A'}\n  " \
        "Orders: #{c['orders_count'] || 0}\n  " \
        "Total spent: #{format_sapo_currency(c['total_spent'] || 0)}"
    end.join("\n\n")
  end
end
