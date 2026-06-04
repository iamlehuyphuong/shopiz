# Copilot tool: Update customer on Haravan.
class Captain::Tools::Copilot::HaravanUpdateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def self.name
    'haravan_update_customer'
  end

  description 'Update an existing customer on Haravan by customer ID.'
  param :customer_id, type: :string, desc: 'Haravan customer ID', required: true
  param :first_name, type: :string, desc: 'Updated first name', required: false
  param :last_name, type: :string, desc: 'Updated last name', required: false
  param :phone, type: :string, desc: 'Updated phone', required: false
  param :email, type: :string, desc: 'Updated email', required: false

  def execute(customer_id:, first_name: nil, last_name: nil, phone: nil, email: nil)
    return 'Haravan integration is not connected' unless haravan_active?

    body = build_update_body(first_name, last_name, phone, email)
    result = haravan_put("customers/#{customer_id}.json", body)
    return 'Failed to update customer on Haravan.' if result.nil?

    customer = result['customer']
    return 'Haravan returned an error.' if customer.nil?

    format_success(customer)
  end

  def active?
    @user.present? && haravan_active?
  end

  private

  def build_update_body(first_name, last_name, phone, email)
    customer = {}
    customer[:first_name] = first_name if first_name.present?
    customer[:last_name] = last_name if last_name.present?
    customer[:phone] = phone if phone.present?
    customer[:email] = email if email.present?
    { customer: customer }
  end

  def format_success(customer)
    <<~RESPONSE.strip
      Customer updated on Haravan!

      ID: #{customer['id']}
      Name: #{customer['first_name']} #{customer['last_name']}
      Phone: #{customer['phone'] || 'N/A'}
      Email: #{customer['email'] || 'N/A'}
    RESPONSE
  end
end
