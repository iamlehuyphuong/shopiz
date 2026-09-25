# Copilot tool: Create customer on Sapo.
class Captain::Tools::Copilot::Sapo::CreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Sapo::Client

  def self.name
    'sapo_create_customer'
  end

  description 'Create a new customer on Sapo.'
  param :first_name, type: :string, desc: 'First name', required: true
  param :last_name, type: :string, desc: 'Last name', required: true
  param :phone, type: :string, desc: 'Phone number', required: false
  param :email, type: :string, desc: 'Email', required: false
  param :address, type: :string, desc: 'Address', required: false

  def execute(first_name:, last_name:, phone: nil, email: nil, address: nil)
    return 'Sapo integration is not connected' unless sapo_active?

    body = build_customer_body(first_name, last_name, phone, email, address)
    result = sapo_post('customers.json', body)
    return 'Failed to create customer on Sapo.' if result.nil?

    customer = result['customer']
    return 'Sapo returned an error.' if customer.nil?

    save_external_customer_id(@conversation.contact, 'sapo', customer['id']) if @conversation&.contact

    format_success(customer)
  end

  def active?
    @user.present? && sapo_active?
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
      Customer created on Sapo!

      ID: #{customer['id']}
      Name: #{customer['first_name']} #{customer['last_name']}
      Phone: #{customer['phone'] || 'N/A'}
      Email: #{customer['email'] || 'N/A'}
    RESPONSE
  end
end
