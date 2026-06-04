# Copilot tool: Create customer on Haravan.
class Captain::Tools::Copilot::HaravanCreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def self.name
    'haravan_create_customer'
  end

  description 'Create a new customer on Haravan.'
  param :first_name, type: :string, desc: 'First name', required: true
  param :last_name, type: :string, desc: 'Last name', required: true
  param :phone, type: :string, desc: 'Phone number', required: false
  param :email, type: :string, desc: 'Email', required: false
  param :address, type: :string, desc: 'Address', required: false

  def execute(first_name:, last_name:, phone: nil, email: nil, address: nil)
    return 'Haravan integration is not connected' unless haravan_active?

    body = build_customer_body(first_name, last_name, phone, email, address)
    result = haravan_post('customers.json', body)
    return 'Failed to create customer on Haravan.' if result.nil?

    customer = result['customer']
    return 'Haravan returned an error.' if customer.nil?

    format_success(customer)
  end

  def active?
    @user.present? && haravan_active?
  end

  private

  def build_customer_body(first_name, last_name, phone, email, address)
    customer = { first_name: first_name, last_name: last_name }
    customer[:phone] = phone if phone.present?
    customer[:email] = email if email.present?
    customer[:addresses] = [{ address1: address }] if address.present?
    { customer: customer }
  end

  def format_success(customer)
    <<~RESPONSE.strip
      ✅ Customer created on Haravan!

      ID: #{customer['id']}
      Name: #{customer['first_name']} #{customer['last_name']}
      Phone: #{customer['phone'] || 'N/A'}
      Email: #{customer['email'] || 'N/A'}
    RESPONSE
  end
end
