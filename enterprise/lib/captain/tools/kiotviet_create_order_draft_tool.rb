# Public tool: Create a draft ConversationOrder from the current conversation.
# Looks up products on KiotViet by code, validates stock, and creates
# a draft order in Shopiz for agent review — does NOT push to KiotViet.
class Captain::Tools::KiotvietCreateOrderDraftTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::KiotvietClient

  description 'Create a draft order with KiotViet products for the current contact. ' \
              'The order is saved as a draft for agent review, NOT submitted to KiotViet directly.'
  param :product_codes, type: 'string', desc: 'Comma-separated KiotViet product codes (e.g. "SP001,SP002")', required: true
  param :quantities, type: 'string', desc: 'Comma-separated quantities matching each product code (e.g. "2,1")', required: true
  param :customer_note, type: 'string', desc: 'Optional note from the customer', required: false

  def active?
    kiotviet_active?
  end

  def perform(tool_context, product_codes:, quantities:, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    codes = parse_list(product_codes)
    qtys = parse_quantities(quantities, codes.size)
    return 'Product codes and quantities must match' if codes.size != qtys.size

    log_tool_usage('kiotviet_create_order_draft', { codes: codes, quantities: qtys })

    items_data = resolve_products(codes, qtys)
    return items_data[:error] if items_data[:error]

    order = create_draft_order(conversation, contact, items_data[:items], customer_note)
    format_draft_result(order, items_data)
  end

  private

  def parse_list(str)
    str.split(',').map(&:strip).reject(&:blank?)
  end

  def parse_quantities(str, expected_size)
    parsed = str.split(',').map { |q| q.strip.to_i }
    # If only one quantity provided, apply to all codes
    return Array.new(expected_size, parsed.first) if parsed.size == 1 && expected_size > 1

    parsed
  end

  def resolve_products(codes, qtys)
    items = []
    warnings = []

    codes.each_with_index do |code, idx|
      product = lookup_product_by_code(code)
      return { error: "Product '#{code}' not found on KiotViet" } if product.nil?

      stock = compute_stock(product['inventories'])
      warnings << "#{product['name']} (#{code}): only #{stock[:total]} in stock, requested #{qtys[idx]}" if stock[:total] < qtys[idx]

      items << {
        product_name: product['fullName'] || product['name'],
        product_id: product['id'].to_s,
        product_source: 'kiotviet',
        quantity: qtys[idx],
        unit_price: product['basePrice'].to_f,
        product_thumbnail: product.dig('images', 0),
        code: code,
        stock: stock
      }
    end

    { items: items, warnings: warnings }
  end

  def lookup_product_by_code(code)
    result = kiotviet_get('products/code', { code: code })
    # API returns single product object or array
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def compute_stock(inventories)
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

  def create_draft_order(conversation, contact, items, customer_note)
    order = conversation.conversation_orders.new(
      account: conversation.account,
      contact: contact,
      status: :draft,
      customer_name: contact.name,
      customer_phone: contact.phone_number,
      customer_address: contact.additional_attributes&.dig('address'),
      customer_note: customer_note,
      external_source: 'kiotviet'
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

  def format_draft_result(order, items_data)
    lines = ["✅ Draft order ##{order.id} created successfully!\n"]
    lines << 'Items:'

    items_data[:items].each do |item|
      lines << "  • #{item[:product_name]} (#{item[:code]}) × #{item[:quantity]} — #{format_vnd(item[:unit_price])} each"
    end

    lines << "\nTotal: #{format_vnd(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"

    if items_data[:warnings].present?
      lines << "\n⚠️ Stock warnings:"
      items_data[:warnings].each { |w| lines << "  • #{w}" }
    end

    lines << "\n📋 This is a DRAFT order. An agent will review and confirm it."
    lines.join("\n")
  end
end
