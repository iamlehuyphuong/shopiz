# Copilot tool: Get detailed information about a specific KiotViet order/invoice.
class Captain::Tools::Copilot::KiotvietGetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_get_order_detail'
  end

  description 'Get detailed information about a specific KiotViet order or invoice, ' \
              'including items, payment status, delivery details, and timeline.'
  param :order_code, type: :string, desc: 'Order/invoice code (e.g. "HD000123")', required: false
  param :order_id, type: :integer, desc: 'Order/invoice ID on KiotViet', required: false

  def execute(order_code: nil, order_id: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?
    return 'Please provide either order_code or order_id' if order_code.blank? && order_id.blank?

    invoice = fetch_invoice(order_code, order_id)
    return build_not_found_message(order_code, order_id) if invoice.nil?

    format_detail(invoice)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def fetch_invoice(code, id)
    endpoint = code.present? ? "invoices/code/#{code}" : "invoices/#{id}"
    result = kiotviet_get(endpoint)
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def build_not_found_message(code, id)
    identifier = code.present? ? "with code '#{code}'" : "with ID #{id}"
    "Invoice not found #{identifier}"
  end

  def format_detail(inv)
    [
      format_header(inv),
      format_customer(inv),
      format_items(inv),
      format_payment(inv),
      format_delivery(inv)
    ].compact.join("\n")
  end

  def format_header(inv)
    [
      "📋 Invoice #{inv['code']} (ID: #{inv['id']})",
      "Status: #{resolve_status(inv['status'])}",
      "Date: #{parse_date(inv['createdDate'])}",
      "Branch: #{inv['branchName'] || 'N/A'}"
    ].join("\n")
  end

  def format_customer(inv)
    return nil if inv['customerName'].blank?

    "\n👤 Customer: #{inv['customerName']}\n   Phone: #{inv['customerContactNumber'] || 'N/A'}"
  end

  def format_items(inv)
    items = inv['invoiceDetails'] || []
    return nil if items.blank?

    lines = ["\n📦 Items (#{items.size}):"]
    items.each { |item| lines << format_single_item(item) }
    lines.join("\n")
  end

  def format_single_item(item)
    price_info = "#{format_vnd(item['price'])} × #{item['quantity']}"
    discount_info = item['discount'].to_f.positive? ? " (discount: #{format_vnd(item['discount'])})" : ''
    "  • #{item['productName']} (#{item['productCode']}) — #{price_info}#{discount_info}"
  end

  def format_payment(inv)
    lines = ["\n💰 Payment:", "  Subtotal: #{format_vnd(inv['total'])}"]
    lines << "  Discount: #{format_vnd(inv['discount'])}" if inv['discount'].to_f.positive?
    lines << "  Total Paid: #{format_vnd(inv['totalPayment'])}"
    remaining = inv['total'].to_f - inv['totalPayment'].to_f
    lines << "  Remaining: #{format_vnd(remaining)}" if remaining.positive?
    lines.join("\n")
  end

  def format_delivery(inv)
    delivery = inv['deliveryDetail'] || inv['orderDelivery']
    return nil if delivery.blank?

    lines = delivery_base_lines(delivery)
    lines << "  Status: #{resolve_delivery_status(delivery['status'])}" if delivery['status'].present?
    lines << "  Tracking: #{delivery['deliveryCode']}" if delivery['deliveryCode'].present?
    lines.join("\n")
  end

  def delivery_base_lines(delivery)
    [
      "\n🚚 Delivery:",
      "  Receiver: #{delivery['receiver'] || 'N/A'}",
      "  Phone: #{delivery['contactNumber'] || 'N/A'}",
      "  Address: #{delivery['address'] || 'N/A'}"
    ]
  end

  def resolve_status(status)
    { 1 => '✅ Active', 2 => '❌ Cancelled', 3 => '↩️ Returned' }[status] || "Unknown (#{status})"
  end

  def resolve_delivery_status(status)
    { 1 => 'Pending', 2 => 'Confirmed', 3 => 'Not shipped',
      4 => 'Shipping', 5 => 'Delivered', 6 => 'Cancelled' }[status] || "Unknown (#{status})"
  end

  def parse_date(date_str)
    return 'N/A' if date_str.blank?

    Time.zone.parse(date_str).strftime('%Y-%m-%d %H:%M')
  end
end
