# Copilot tool: Create customer on WooCommerce.
class Captain::Tools::Copilot::WoocommerceCreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient

  def self.name
    'woocommerce_create_customer'
  end

  description 'Create a new customer on WooCommerce.'
  param :first_name, type: :string, desc: 'First name', required: true
  param :last_name, type: :string, desc: 'Last name', required: true
  param :email, type: :string, desc: 'Email (required by WooCommerce)', required: true
  param :phone, type: :string, desc: 'Phone number', required: false

  def execute(first_name:, last_name:, email:, phone: nil)
    return 'WooCommerce integration is not connected' unless woocommerce_active?

    body = { first_name: first_name, last_name: last_name, email: email }
    body[:billing] = { phone: phone } if phone.present?

    result = woocommerce_post('customers', body)
    return 'Failed to create customer on WooCommerce.' if result.nil?
    return "WooCommerce error: #{result['message']}" if result['id'].nil?

    format_success(result)
  end

  def active?
    @user.present? && woocommerce_active?
  end

  private

  def format_success(customer)
    <<~RESPONSE.strip
      ✅ Customer created on WooCommerce!

      ID: #{customer['id']}
      Name: #{customer['first_name']} #{customer['last_name']}
      Email: #{customer['email']}
      Phone: #{customer.dig('billing', 'phone') || 'N/A'}
    RESPONSE
  end
end
