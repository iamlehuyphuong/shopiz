# Copilot tool: Create a customer on Nhanh.vn.
# Nhanh.vn uses mobile as key — upserts (add if new, update if exists).
class Captain::Tools::Copilot::Nhanhvn::CreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Nhanhvn::Client

  def self.name
    'nhanhvn_create_customer'
  end

  description 'Create a new customer on Nhanh.vn. Uses phone number as key — ' \
              'if customer already exists, their info will be updated instead.'
  param :name, type: :string, desc: 'Customer name', required: true
  param :phone, type: :string, desc: 'Customer phone number', required: true
  param :email, type: :string, desc: 'Customer email', required: false
  param :address, type: :string, desc: 'Customer address', required: false
  param :city, type: :string, desc: 'City name', required: false
  param :district, type: :string, desc: 'District name', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(name:, phone:, email: nil, address: nil, city: nil, district: nil)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    customer_data = build_customer_data(name, phone, email, address, city, district)
    result = nhanhvn_post('/api/customer/add', [customer_data])
    return 'Failed to create customer on Nhanh.vn. Check API logs.' if result.nil?

    format_success(customer_data, result)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def build_customer_data(name, phone, email, address, city, district)
    data = { name: name, mobile: phone }
    data[:email] = email if email.present?
    data[:address] = address if address.present?
    data[:cityName] = city if city.present?
    data[:districtName] = district if district.present?
    data
  end

  def format_success(data, result)
    <<~RESPONSE.strip
      Customer created/updated successfully on Nhanh.vn!

      Name: #{data[:name]}
      Phone: #{data[:mobile]}
      Email: #{data[:email] || 'N/A'}
      Address: #{data[:address] || 'N/A'}
      City: #{data[:cityName] || 'N/A'}
      District: #{data[:districtName] || 'N/A'}
      API Response: #{result['data'] || 'OK'}
    RESPONSE
  end
end
