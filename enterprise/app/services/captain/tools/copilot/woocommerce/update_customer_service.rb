# Copilot tool: Update customer on WooCommerce.
class Captain::Tools::Copilot::Woocommerce::UpdateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Woocommerce::Client

  def self.name
    'woocommerce_update_customer'
  end

  description 'Update an existing customer on WooCommerce by customer ID.'
  param :customer_id, type: :string, desc: 'WooCommerce customer ID', required: true
  param :first_name, type: :string, desc: 'Updated first name', required: false
  param :last_name, type: :string, desc: 'Updated last name', required: false
  param :email, type: :string, desc: 'Updated email', required: false
  param :phone, type: :string, desc: 'Updated phone', required: false

  def execute(customer_id:, first_name: nil, last_name: nil, email: nil, phone: nil)
    return 'WooCommerce integration is not connected' unless woocommerce_active?

    body = build_body(first_name, last_name, email, phone)
    result = woocommerce_put("customers/#{customer_id}", body)
    return 'Failed to update customer on WooCommerce.' if result.nil?
    return "WooCommerce error: #{result['message']}" if result['id'].nil?

    format_success(result)
  end

  def active?
    @user.present? && woocommerce_active?
  end

  private

  def build_body(first_name, last_name, email, phone)
    body = {}
    body[:first_name] = first_name if first_name.present?
    body[:last_name] = last_name if last_name.present?
    body[:email] = email if email.present?
    body[:billing] = { phone: phone } if phone.present?
    body
  end

  def format_success(customer)
    <<~RESPONSE.strip
      Customer updated on WooCommerce!

      ID: #{customer['id']}
      Name: #{customer['first_name']} #{customer['last_name']}
      Email: #{customer['email']}
      Phone: #{customer.dig('billing', 'phone') || 'N/A'}
    RESPONSE
  end
end
