class Captain::Tools::Copilot::SapoSearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SapoClient
  def self.name
    'sapo_search_orders'
  end

  description 'Search for orders on the Sapo store by customer email or phone.'
  param :email, type: :string, desc: 'Customer email address'
  param :phone, type: :string, desc: 'Customer phone number (optional)'

  def execute(**args)
    arguments = args.stringify_keys
    return 'Sapo integration is not connected.' unless sapo_active?

    customer_id = find_sapo_customer_id(arguments['email'], arguments['phone'])
    return 'Customer not found in Sapo.' if customer_id.nil?

    orders = fetch_orders(customer_id)
    return 'No orders found.' if orders.blank?

    format_orders(orders)
  end

  private

  def find_sapo_customer_id(email, phone)
    query = email.presence || phone
    return nil if query.blank?

    result = sapo_get('customers/search.json', { query: query })
    result&.dig('customers')&.first&.dig('id')
  end

  def fetch_orders(customer_id)
    result = sapo_get('orders.json', { customer_id: customer_id, status: 'any', limit: 10 })
    result&.dig('orders') || []
  end

  def format_orders(orders)
    orders.map do |o|
      items = o['line_items']&.map { |li| "#{li['name']} x#{li['quantity']}" }
      "**Order ##{o['order_number']}** (#{o['financial_status']})\n " \
        "Total: #{format_sapo_currency(o['total_price'])}\n " \
        "Items: #{items&.join(', ') || 'N/A'}\n " \
        "Date: #{o['created_on']}"
    end.join("\n\n")
  end
end
