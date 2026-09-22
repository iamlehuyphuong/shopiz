# Copilot tool: Update an existing customer on KiotViet.
class Captain::Tools::Copilot::Kiotviet::UpdateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Kiotviet::Client

  def self.name
    'kiotviet_update_customer'
  end

  description 'Update an existing customer on KiotViet. Requires the customer ID.'
  param :customer_id, type: :integer, desc: 'KiotViet customer ID (required)', required: true
  param :name, type: :string, desc: 'Updated customer name', required: false
  param :phone, type: :string, desc: 'Updated phone number', required: false
  param :email, type: :string, desc: 'Updated email address', required: false
  param :address, type: :string, desc: 'Updated address', required: false
  param :comment, type: :string, desc: 'Updated notes', required: false

  def execute(customer_id:, name: nil, email: nil, phone: nil, address: nil, comment: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?
    return 'Customer ID is required' if customer_id.blank?

    body = build_update_body(customer_id, name: name, phone: phone, email: email, address: address, comment: comment)

    # Only proceed if there's something to update
    return 'No fields to update. Please provide at least one field to change.' if body.keys == [:id]

    result = kiotviet_put("customers/#{customer_id}", body)

    return 'Failed to update customer on KiotViet. Please check the ID and try again.' if result.nil?
    return "KiotViet error: #{result['responseStatus']['message'] || 'Unknown error'}" if result['responseStatus'].present?

    format_result(result)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def build_update_body(customer_id, name:, phone:, email:, address:, comment:)
    body = { id: customer_id }
    body[:name] = name if name.present?
    body[:contactNumber] = phone if phone.present?
    body[:email] = email if email.present?
    body[:address] = address if address.present?
    body[:comment] = comment if comment.present?
    body
  end

  def format_result(customer)
    <<~RESULT.strip
      ✅ Customer updated successfully on KiotViet!

      Code: #{customer['code']}
      Name: #{customer['name']}
      Phone: #{customer['contactNumber'] || 'N/A'}
      Email: #{customer['email'] || 'N/A'}
      Address: #{customer['address'] || 'N/A'}
      ID: #{customer['id']}
    RESULT
  end
end
