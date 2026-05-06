# Copilot tool: Update a customer on Nhanh.vn.
# Nhanh.vn /api/customer/add uses mobile as key — updates if customer exists.
class Captain::Tools::Copilot::NhanhvnUpdateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_update_customer'
  end

  description 'Update an existing customer on Nhanh.vn by phone number. ' \
              'Uses the same /api/customer/add endpoint which upserts by mobile.'
  param :phone, type: :string, desc: 'Customer phone number (used as key to find the customer)', required: true
  param :name, type: :string, desc: 'Updated customer name', required: false
  param :email, type: :string, desc: 'Updated email', required: false
  param :address, type: :string, desc: 'Updated address', required: false
  param :city, type: :string, desc: 'Updated city name', required: false
  param :district, type: :string, desc: 'Updated district name', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(phone:, name: nil, email: nil, address: nil, city: nil, district: nil)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    customer_data = build_update_data(phone, name, email, address, city, district)
    result = nhanhvn_post('/api/customer/add', [customer_data])
    return 'Failed to update customer on Nhanh.vn. Check API logs.' if result.nil?

    format_success(customer_data, result)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def build_update_data(phone, name, email, address, city, district)
    data = { mobile: phone }
    data[:name] = name if name.present?
    data[:email] = email if email.present?
    data[:address] = address if address.present?
    data[:cityName] = city if city.present?
    data[:districtName] = district if district.present?
    data
  end

  def format_success(data, result)
    <<~RESPONSE.strip
      ✅ Customer updated successfully on Nhanh.vn!

      Phone: #{data[:mobile]}
      Name: #{data[:name] || '(unchanged)'}
      Email: #{data[:email] || '(unchanged)'}
      Address: #{data[:address] || '(unchanged)'}
      City: #{data[:cityName] || '(unchanged)'}
      District: #{data[:districtName] || '(unchanged)'}
      API Response: #{result['data'] || 'OK'}
    RESPONSE
  end
end
