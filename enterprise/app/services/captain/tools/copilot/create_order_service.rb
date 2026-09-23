class Captain::Tools::Copilot::CreateOrderService < Captain::Tools::BaseTool
  def self.name
    'create_order'
  end

  description 'Create a draft order for the customer'
  param :conversation_id, type: :integer, desc: 'Conversation display ID to attach the order to', required: true
  param :product_items, type: :string, desc: 'JSON array of items: [{"id":"SP001","qty":2}]', required: true
  param :customer_name, type: :string, desc: 'Customer name', required: false
  param :customer_phone, type: :string, desc: 'Customer phone', required: false
  param :delivery_address, type: :string, desc: 'Delivery address', required: false
  param :note, type: :string, desc: 'Order note', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(conversation_id:, product_items:, customer_name: nil, customer_phone: nil, delivery_address: nil, note: nil)
    return 'AI order creation is disabled for this account. Enable it in Sales Settings.' unless @conversation&.account&.ai_allow_create_order

    conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless conversation

    items = parse_product_items(product_items)
    return 'Invalid product_items format. Expected array with name, qty, price.' if items.blank?

    order = build_draft_order(conversation, items,
                              customer_name: customer_name, customer_phone: customer_phone,
                              delivery_address: delivery_address, note: note)
    format_order_result(order)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    @user.present?
  end

  private

  def find_conversation(display_id)
    Conversation.find_by(account_id: @assistant.account_id, display_id: display_id)
  end

  def parse_product_items(raw)
    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
    return nil unless parsed.is_a?(Array) && parsed.all? { |i| i['name'].present? }

    parsed.map do |i|
      {
        product_name: i['name'],
        product_id: i['id'] || 'custom',
        quantity: (i['qty'] || i['quantity'] || 1).to_i,
        unit_price: i['price'].to_f,
        product_source: 'shopiz'
      }
    end
  rescue JSON::ParserError
    nil
  end

  def build_draft_order(conversation, items, customer_name:, customer_phone:, delivery_address:, note:)
    contact = conversation.contact
    active_platform = @assistant.account.active_ecommerce_platform
    source = active_platform.presence || 'shopiz'

    order = conversation.conversation_orders.new(
      account_id: @assistant.account_id, contact: contact, status: :draft,
      customer_name: customer_name.presence || contact&.name,
      customer_phone: customer_phone.presence || contact&.phone_number,
      customer_address: delivery_address.presence || contact&.additional_attributes&.dig('address'),
      customer_note: note,
      external_source: source
    )
    items.each { |item| order.items.build(item) }
    order.save!
    order
  end

  def format_order_result(order)
    lines = ["✅ Local draft order ##{order.id} created for conversation ##{order.conversation.display_id}\n"]
    order.items.each { |item| lines << "  • #{item.product_name} × #{item.quantity} — #{format_currency(item.unit_price)}" }
    lines << "\nTotal: #{format_currency(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    lines << "\n📋 Status: DRAFT — Use the confirm_order tool to finalize."
    lines.join("\n")
  end

  def format_currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: 'đ', format: '%n%u', precision: 0)
  end
end
