# Copilot tool: Create a new customer on KiotViet.
class Captain::Tools::Copilot::KiotvietCreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_create_customer'
  end

  description 'Create a new customer on KiotViet with their contact information.'
  param :name, type: :string, desc: 'Customer name (required)', required: true
  param :phone, type: :string, desc: 'Phone number', required: false
  param :email, type: :string, desc: 'Email address', required: false
  param :address, type: :string, desc: 'Full address', required: false
  param :gender, type: :boolean, desc: 'Gender: true=Male, false=Female', required: false
  param :comment, type: :string, desc: 'Additional notes about the customer', required: false

  def execute(name:, phone: nil, email: nil, address: nil, gender: nil, comment: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?
    return 'Customer name is required' if name.blank?

    body = build_customer_body(name, phone: phone, email: email, address: address, gender: gender, comment: comment)
    result = kiotviet_post('customers', body)

    return 'Failed to create customer on KiotViet. Please check the connection and try again.' if result.nil?
    return "KiotViet error: #{result['responseStatus']&.dig('message') || result['message'] || 'Unknown error'}" if result['id'].blank?

    format_result(result)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def build_customer_body(name, phone:, email:, address:, gender:, comment:)
    body = { name: name }
    body[:contactNumber] = phone if phone.present?
    body[:email] = email if email.present?
    body[:address] = address if address.present?
    body[:gender] = gender unless gender.nil?
    body[:comment] = comment if comment.present?
    body
  end

  def format_result(customer)
    <<~RESULT.strip
      ✅ Customer created successfully on KiotViet!

      Code: #{customer['code']}
      Name: #{customer['name']}
      Phone: #{customer['contactNumber'] || 'N/A'}
      Email: #{customer['email'] || 'N/A'}
      Address: #{customer['address'] || 'N/A'}
      ID: #{customer['id']}
    RESULT
  end
end
