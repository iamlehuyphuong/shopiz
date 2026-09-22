# Copilot tool: Update customer on Shopify.
class Captain::Tools::Copilot::Shopify::UpdateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Shopify::Client

  def self.name
    'shopify_update_customer'
  end

  description 'Update an existing customer on Shopify by customer ID.'
  param :customer_id, type: :string, desc: 'Shopify customer ID', required: true
  param :first_name, type: :string, desc: 'Updated first name', required: false
  param :last_name, type: :string, desc: 'Updated last name', required: false
  param :phone, type: :string, desc: 'Updated phone', required: false
  param :email, type: :string, desc: 'Updated email', required: false

  def execute(customer_id:, first_name: nil, last_name: nil, phone: nil, email: nil)
    return 'Shopify integration is not connected' unless shopify_active?

    body = build_body(first_name, last_name, phone, email)
    result = shopify_put("customers/#{customer_id}.json", body)
    return 'Failed to update customer on Shopify.' if result.nil?

    customer = result['customer']
    return "Shopify error: #{result['errors']}" if customer.nil?

    format_success(customer)
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def build_body(first_name, last_name, phone, email)
    customer = {}
    customer[:first_name] = first_name if first_name.present?
    customer[:last_name] = last_name if last_name.present?
    customer[:phone] = phone if phone.present?
    customer[:email] = email if email.present?
    { customer: customer }
  end

  def format_success(customer)
    <<~RESPONSE.strip
      Customer updated on Shopify!

      ID: #{customer['id']}
      Name: #{customer['first_name']} #{customer['last_name']}
      Phone: #{customer['phone'] || 'N/A'}
      Email: #{customer['email'] || 'N/A'}
    RESPONSE
  end
end
