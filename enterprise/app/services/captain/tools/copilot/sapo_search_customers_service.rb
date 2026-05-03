class Captain::Tools::Copilot::SapoSearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SapoClient
  def self.name
    'sapo_search_customers'
  end

  description 'Search for customers on the Sapo store by name, email, or phone.'
  param :query, type: :string, desc: 'Customer name, email, or phone to search'

  def execute(**args)
    arguments = args.stringify_keys
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
