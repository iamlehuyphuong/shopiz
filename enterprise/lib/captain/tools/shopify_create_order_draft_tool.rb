# Public tool: Create a draft ConversationOrder from Shopify products.
class Captain::Tools::ShopifyCreateOrderDraftTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::ShopifyClient

  description 'Create a draft order with Shopify products for the current contact. ' \
              'The order is saved as a draft for agent review, NOT submitted to Shopify directly.'
  param :product_ids, type: 'string', desc: 'Comma-separated Shopify product IDs (e.g. "123,456")', required: true
  param :quantities, type: 'string', desc: 'Comma-separated quantities matching each product (e.g. "2,1")', required: true
  param :customer_note, type: 'string', desc: 'Optional note from the customer', required: false

  def active?
    shopify_active?
  end

  def perform(tool_context, product_ids:, quantities:, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    ids = product_ids.split(',').map(&:strip).reject(&:blank?)
    qtys = parse_quantities(quantities, ids.size)
    return 'Product IDs and quantities must match' if ids.size != qtys.size

    log_tool_usage('shopify_create_order_draft', { ids: ids, quantities: qtys })

    items_data = resolve_products(ids, qtys)
    return items_data[:error] if items_data[:error]

    order = create_draft_order(conversation, contact, items_data[:items], customer_note)
    format_draft_result(order, items_data)
  end

  private

  def parse_quantities(str, expected_size)
    parsed = str.split(',').map { |q| q.strip.to_i }
    return Array.new(expected_size, parsed.first) if parsed.size == 1 && expected_size > 1

    parsed
  end

  def resolve_products(ids, qtys)
    items = []
    warnings = []
    ids.each_with_index do |id, idx|
      product = fetch_product(id)
      return { error: "Product ID '#{id}' not found on Shopify" } if product.nil?

      stock = compute_stock(product['variants'])
      warnings << "#{product['title']} (ID: #{id}): only #{stock[:total]} in stock" if stock[:total] < qtys[idx]
      items << build_item_hash(product, id, qtys[idx])
    end
    { items: items, warnings: warnings }
  end

  def fetch_product(id)
    result = shopify_get("products/#{id}.json")
    result&.dig('product')
  end

  def compute_stock(variants)
    total = variants&.sum { |v| v['inventory_quantity'].to_i } || 0
    status = if total > 5
               'In Stock'
             else
               (total.positive? ? 'Low Stock' : 'Out of Stock')
             end
    { total: total, status: status }
  end

  def build_item_hash(product, id, qty)
    variant = product['variants']&.first
    {
      product_name: product['title'], product_id: id.to_s, product_source: 'shopify',
      quantity: qty, unit_price: variant&.dig('price').to_f,
      product_thumbnail: product.dig('image', 'src')
    }
  end

  def create_draft_order(conversation, contact, items, customer_note)
    order = conversation.conversation_orders.new(
      account: conversation.account, contact: contact, status: :draft,
      customer_name: contact.name, customer_phone: contact.phone_number,
      customer_address: contact.additional_attributes&.dig('address'),
      customer_note: customer_note,
      external_source: 'shopify'
    )
    items.each { |item| order.items.build(item.slice(:product_name, :product_id, :product_source, :quantity, :unit_price, :product_thumbnail)) }
    order.save!
    order
  end

  def format_draft_result(order, items_data)
    lines = ["✅ Draft order ##{order.id} created!\n", 'Items:']
    items_data[:items].each { |i| lines << "  • #{i[:product_name]} × #{i[:quantity]} — #{format_currency(i[:unit_price], 'VND')} each" }
    lines << "\nTotal: #{format_currency(order.total_amount, 'VND')}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    if items_data[:warnings].present?
      lines << "\n⚠️ Stock warnings:"
      items_data[:warnings].each { |w| lines << "  • #{w}" }
    end
    lines << "\n📋 This is a DRAFT order. An agent will review and confirm it."
    lines.join("\n")
  end
end
