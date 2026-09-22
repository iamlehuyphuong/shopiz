# Public tool: Create a draft ConversationOrder from the current conversation.
# Looks up products on Nhanh.vn by code, validates stock, and creates
# a draft order in Shopiz for agent review — does NOT push to Nhanh.vn.
class Captain::Tools::Nhanhvn::CreateOrderDraftTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Nhanhvn::Client

  description 'Create a draft order with Nhanh.vn products for the current contact. ' \
              'The order is saved as a draft for agent review, NOT submitted to Nhanh.vn directly.'
  param :product_codes, type: 'string', desc: 'Comma-separated Nhanh.vn product codes (e.g. "SP001,SP002")', required: true
  param :quantities, type: 'string', desc: 'Comma-separated quantities matching each product code (e.g. "2,1")', required: true
  param :customer_note, type: 'string', desc: 'Optional note from the customer', required: false

  def active?
    nhanhvn_active?
  end

  def perform(tool_context, product_codes:, quantities:, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    codes = parse_list(product_codes)
    qtys = parse_quantities(quantities, codes.size)
    return 'Product codes and quantities must match' if codes.size != qtys.size

    log_tool_usage('nhanhvn_create_order_draft', { codes: codes, quantities: qtys })

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
    return Array.new(expected_size, parsed.first) if parsed.size == 1 && expected_size > 1

    parsed
  end

  def resolve_products(codes, qtys)
    items = []
    warnings = []

    codes.each_with_index do |code, idx|
      product = lookup_product_by_code(code)
      return { error: "Product '#{code}' not found on Nhanh.vn" } if product.nil?

      stock = compute_stock(product['inventory'])
      warnings << "#{product['name']} (#{code}): only #{stock[:total]} in stock, requested #{qtys[idx]}" if stock[:total] < qtys[idx]

      items << build_item_hash(product, code, qtys[idx], stock)
    end

    { items: items, warnings: warnings }
  end

  def build_item_hash(product, code, qty, stock)
    {
      product_name: product['name'],
      product_id: product['idNhanh'].to_s,
      product_source: 'nhanhvn',
      quantity: qty,
      unit_price: product['price'].to_f,
      product_thumbnail: product['image'],
      code: code,
      stock: stock
    }
  end

  def lookup_product_by_code(code)
    result = nhanhvn_post('/api/product/search', { code: code, icpp: 1 })
    products_hash = result&.dig('data', 'products')
    return nil unless products_hash.is_a?(Hash)

    products_hash.values.first
  end

  def compute_stock(inventory)
    available = inventory&.dig('available').to_i
    status = if available > 5
               'In Stock'
             else
               (available.positive? ? 'Low Stock' : 'Out of Stock')
             end
    { total: available, status: status }
  end

  def create_draft_order(conversation, contact, items, customer_note)
    order = conversation.conversation_orders.new(
      account: conversation.account, contact: contact, status: :draft,
      customer_name: contact.name, customer_phone: contact.phone_number,
      customer_address: contact.additional_attributes&.dig('address'),
      customer_note: customer_note,
      external_source: 'nhanhvn'
    )
    items.each { |item| order.items.build(item.slice(:product_name, :product_id, :product_source, :quantity, :unit_price, :product_thumbnail)) }
    order.save!
    order
  end

  def format_draft_result(order, items_data)
    lines = ["✅ Draft order ##{order.id} created successfully!\n", 'Items:']
    items_data[:items].each do |item|
      lines << "  • #{item[:product_name]} (#{item[:code]}) × #{item[:quantity]} — #{format_currency(item[:unit_price])} each"
    end
    lines << "\nTotal: #{format_currency(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    append_warnings(lines, items_data[:warnings])
    lines << "\n📋 This is a DRAFT order. An agent will review and confirm it."
    lines.join("\n")
  end

  def append_warnings(lines, warnings)
    return if warnings.blank?

    lines << "\n⚠️ Stock warnings:"
    warnings.each { |warning| lines << "  • #{warning}" }
  end
end
