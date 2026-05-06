# Copilot tool: Create draft order with Shopify products.
class Captain::Tools::Copilot::ShopifyCreateOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::ShopifyClient

  def self.name
    'shopify_create_order'
  end

  description 'Create a draft order with Shopify products for agent review.'
  param :conversation_id, type: :integer, desc: 'Conversation display ID', required: true
  param :product_items, type: :string, desc: 'JSON array: [{"id":"123","qty":2}]', required: true
  param :customer_name, type: :string, desc: 'Customer name', required: false
  param :customer_phone, type: :string, desc: 'Customer phone', required: false
  param :delivery_address, type: :string, desc: 'Delivery address', required: false
  param :note, type: :string, desc: 'Order note', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(conversation_id:, product_items:, customer_name: nil, customer_phone: nil, delivery_address: nil, note: nil)
    return 'Shopify integration is not connected' unless shopify_active?

    conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless conversation

    items = parse_items(product_items)
    return 'Invalid product_items format' if items.nil?

    resolved = resolve_all(items)
    return resolved[:error] if resolved[:error]

    order = build_draft(conversation, resolved[:items],
                        customer_name: customer_name, customer_phone: customer_phone,
                        delivery_address: delivery_address, note: note)
    format_result(order, resolved)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    @user.present? && shopify_active?
  end

  private

  def find_conversation(display_id)
    Conversation.find_by(account_id: @assistant.account_id, display_id: display_id)
  end

  def parse_items(raw)
    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
    return nil unless parsed.is_a?(Array) && parsed.all? { |i| i['id'].present? }

    parsed.map { |i| { id: i['id'], qty: (i['qty'] || i['quantity'] || 1).to_i } }
  rescue JSON::ParserError
    nil
  end

  def resolve_all(items)
    resolved = []
    warnings = []
    items.each do |item|
      product = fetch_product(item[:id])
      return { error: "Product '#{item[:id]}' not found on Shopify" } if product.nil?

      stock = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
      warnings << "#{product['title']}: only #{stock} in stock" if stock < item[:qty]
      resolved << build_item(product, item)
    end
    { items: resolved, warnings: warnings }
  end

  def fetch_product(id)
    result = shopify_get("products/#{id}.json")
    result&.dig('product')
  end

  def build_item(product, item)
    variant = product['variants']&.first
    {
      product_name: product['title'], product_id: item[:id].to_s, product_source: 'shopify',
      quantity: item[:qty], unit_price: variant&.dig('price').to_f,
      product_thumbnail: product.dig('image', 'src')
    }
  end

  def build_draft(conversation, items, customer_name:, customer_phone:, delivery_address:, note:)
    contact = conversation.contact
    order = conversation.conversation_orders.new(
      account_id: @assistant.account_id, contact: contact, status: :draft,
      customer_name: customer_name.presence || contact&.name,
      customer_phone: customer_phone.presence || contact&.phone_number,
      customer_address: delivery_address.presence || contact&.additional_attributes&.dig('address'),
      customer_note: note
    )
    items.each { |item| order.items.build(item.slice(:product_name, :product_id, :product_source, :quantity, :unit_price, :product_thumbnail)) }
    order.save!
    order
  end

  def format_result(order, resolved)
    lines = ["✅ Draft order ##{order.id} created for conversation ##{order.conversation.display_id}\n"]
    resolved[:items].each { |i| lines << "  • #{i[:product_name]} × #{i[:quantity]} — #{format_currency(i[:unit_price], 'VND')}" }
    lines << "\nTotal: #{format_currency(order.total_amount, 'VND')}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    if resolved[:warnings].present?
      lines << "\n⚠️ Stock warnings:"
      resolved[:warnings].each { |w| lines << "  • #{w}" }
    end
    lines << "\n📋 Status: DRAFT — Confirm in Orders panel to push to Shopify."
    lines.join("\n")
  end
end
