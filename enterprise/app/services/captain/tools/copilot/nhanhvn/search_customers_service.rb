# Copilot tool: Search Nhanh.vn customers by phone number or list recent customers.
class Captain::Tools::Copilot::Nhanhvn::SearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Nhanhvn::Client

  def self.name
    'nhanhvn_search_customers'
  end

  description 'Search Nhanh.vn customers by phone number or list recent customers'
  param :query, type: :string, desc: 'Search query - phone number to search for', required: true

  def execute(query:)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    customers = search_customers(query)
    return "No Nhanh.vn customers found matching '#{query}'" if customers.blank?

    <<~RESPONSE
      Found #{customers.size} Nhanh.vn customer(s) matching '#{query}':
      #{customers.first(20).map { |c| format_customer(c) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def search_customers(query)
    data = { icpp: 20, mobile: query }
    result = nhanhvn_post('/api/customer/search', data)
    result&.dig('data', 'customers') || []
  end

  def format_customer(customer)
    <<~CUSTOMER.strip
      #{customer['name'] || 'Unknown'} (Code: #{customer['code'] || 'N/A'})
      Phone: #{customer['mobile'] || 'N/A'} | Email: #{customer['email'] || 'N/A'}
      Total Spent: #{format_vnd(customer['totalMoney'])} | Points: #{customer['points'] || 0}
      Level: #{customer['level'] || 'N/A'} | Group: #{customer['group'] || 'N/A'}
    CUSTOMER
  end
end
