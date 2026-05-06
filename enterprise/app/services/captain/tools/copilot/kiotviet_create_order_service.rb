# Copilot tool: Agent creates a draft order via AI with KiotViet products.
# Validates stock, creates ConversationOrder in Shopiz for review.
class Captain::Tools::Copilot::KiotvietCreateOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_create_order'
  end

  description 'Create a draft order with KiotViet products. Validates stock availability ' \
              'and creates the order in Shopiz for agent review before pushing to KiotViet.'
  param :conversation_id, type: :integer, desc: 'Conversation display ID to attach the order to', required: true
  param :product_items, type: :string, desc: 'JSON array of items: [{"code":"SP001","qty":2},{"code":"SP002","qty":1}]', required: true
  param :customer_name, type: :string, desc: 'Customer name (auto-filled from contact if blank)', required: false
  param :customer_phone, type: :string, desc: 'Customer phone (auto-filled from contact if blank)', required: false
  param :delivery_address, type: :string, desc: 'Delivery address', required: false
  param :note, type: :string, desc: 'Order note', required: false

  def execute(conversation_id:, product_items:, customer_name: nil, customer_phone: nil, delivery_address: nil, note: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless conversation

    items = parse_product_items(product_items)
    return 'Invalid product_items format. Expected JSON array: [{"code":"SP001","qty":2}]' if items.nil?

    resolved = resolve_all_products(items)
    return resolved[:error] if resolved[:error]

    order = build_draft_order(conversation, resolved[:items],
                              customer_name: customer_name,
                              customer_phone: customer_phone,
                              delivery_address: delivery_address,
                              note: note)

    format_order_result(order, resolved)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def find_conversation(display_id)
    Conversation.find_by(account_id: @assistant.account_id, display_id: display_id)
  end

  def parse_product_items(raw)
    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
    return nil unless parsed.is_a?(Array) && parsed.all? { |i| i['code'].present? }

    parsed.map { |i| { code: i['code'], qty: (i['qty'] || i['quantity'] || 1).to_i } }
  rescue JSON::ParserError
    nil
  end

  def resolve_all_products(items)
    resolved = []
    warnings = []

    items.each do |item|
      product = lookup_product(item[:code])
      return { error: "Product '#{item[:code]}' not found on KiotViet" } if product.nil?

      stock = calculate_stock(product['inventories'])
      warnings << "#{product['name']} (#{item[:code]}): only #{stock[:total]} in stock, requested #{item[:qty]}" if stock[:total] < item[:qty]

      resolved << {
        product_name: product['fullName'] || product['name'],
        product_id: product['id'].to_s,
        product_source: 'kiotviet',
        quantity: item[:qty],
        unit_price: product['basePrice'].to_f,
        product_thumbnail: product.dig('images', 0),
        code: item[:code],
        stock: stock
      }
    end

    { items: resolved, warnings: warnings }
  end

  def lookup_product(code)
    result = kiotviet_get('products/code', { code: code })
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def calculate_stock(inventories)
    total = inventories&.sum { |inv| inv['onHand'].to_f } || 0
    status = if total > 5
               'In Stock'
             elsif total.positive?
               'Low Stock'
             else
               'Out of Stock'
             end
    { total: total.to_i, status: status }
  end

  def build_draft_order(conversation, items, customer_name:, customer_phone:, delivery_address:, note:)
    contact = conversation.contact

    order = conversation.conversation_orders.new(
      account_id: @assistant.account_id,
      contact: contact,
      status: :draft,
      customer_name: customer_name.presence || contact&.name,
      customer_phone: customer_phone.presence || contact&.phone_number,
      customer_address: delivery_address.presence || contact&.additional_attributes&.dig('address'),
      customer_note: note
    )

    items.each do |item|
      order.items.build(
        product_name: item[:product_name],
        product_id: item[:product_id],
        product_source: item[:product_source],
        quantity: item[:quantity],
        unit_price: item[:unit_price],
        product_thumbnail: item[:product_thumbnail]
      )
    end

    order.save!
    order
  end

  def format_order_result(order, resolved)
    lines = ["✅ Draft order ##{order.id} created for conversation ##{order.conversation.display_id}\n"]

    resolved[:items].each do |item|
      lines << "  • #{item[:product_name]} (#{item[:code]}) × #{item[:quantity]} — #{format_vnd(item[:unit_price])}"
    end

    lines << "\nTotal: #{format_vnd(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    lines << "Address: #{order.customer_address}" if order.customer_address.present?

    if resolved[:warnings].present?
      lines << "\n⚠️ Stock warnings:"
      resolved[:warnings].each { |w| lines << "  • #{w}" }
    end

    lines << "\n📋 Status: DRAFT — Review and confirm in the Orders panel to push to KiotViet."
    lines.join("\n")
  end
end
