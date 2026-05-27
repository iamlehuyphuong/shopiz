# Copilot tool: Agent creates a draft order via AI with Nhanh.vn products.
# Validates stock, creates ConversationOrder in Flowify for review.
class Captain::Tools::Copilot::NhanhvnCreateOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_create_order'
  end

  description 'Create a draft order with Nhanh.vn products. Validates stock availability ' \
              'and creates the order in Flowify for agent review before pushing to Nhanh.vn.'
  param :conversation_id, type: :integer, desc: 'Conversation display ID to attach the order to', required: true
  param :product_items, type: :string, desc: 'JSON array of items: [{"code":"SP001","qty":2},{"code":"SP002","qty":1}]', required: true
  param :customer_name, type: :string, desc: 'Customer name (auto-filled from contact if blank)', required: false
  param :customer_phone, type: :string, desc: 'Customer phone (auto-filled from contact if blank)', required: false
  param :delivery_address, type: :string, desc: 'Delivery address', required: false
  param :note, type: :string, desc: 'Order note', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(conversation_id:, product_items:, customer_name: nil, customer_phone: nil, delivery_address: nil, note: nil)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless conversation

    items = parse_product_items(product_items)
    return 'Invalid product_items format. Expected JSON array: [{"code":"SP001","qty":2}]' if items.nil?

    resolved = resolve_all_products(items)
    return resolved[:error] if resolved[:error]

    order = build_draft_order(conversation, resolved[:items],
                              customer_name: customer_name, customer_phone: customer_phone,
                              delivery_address: delivery_address, note: note)

    format_order_result(order, resolved)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    @user.present? && nhanhvn_active?
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
    items.each { |item| process_item(item, resolved, warnings) || (return { error: "Product '#{item[:code]}' not found" }) }
    { items: resolved, warnings: warnings }
  end

  def process_item(item, resolved, warnings)
    product = lookup_product(item[:code])
    return nil if product.nil?

    stock = compute_stock(product['inventory'])
    warnings << "#{product['name']} (#{item[:code]}): only #{stock[:total]} in stock, requested #{item[:qty]}" if stock[:total] < item[:qty]
    resolved << build_item_hash(product, item)
    true
  end

  def lookup_product(code)
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

  def build_item_hash(product, item)
    {
      product_name: product['name'], product_id: product['idNhanh'].to_s,
      product_source: 'nhanhvn', quantity: item[:qty],
      unit_price: product['price'].to_f, product_thumbnail: product['image'],
      code: item[:code]
    }
  end

  def build_draft_order(conversation, items, customer_name:, customer_phone:, delivery_address:, note:)
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

  def format_order_result(order, resolved)
    lines = ["Draft order ##{order.id} created for conversation ##{order.conversation.display_id}\n"]
    resolved[:items].each { |item| lines << " • #{item[:product_name]} (#{item[:code]}) × #{item[:quantity]} — #{format_vnd(item[:unit_price])}" }
    lines << "\nTotal: #{format_vnd(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    lines << "Address: #{order.customer_address}" if order.customer_address.present?
    append_warnings(lines, resolved[:warnings])
    lines << "\nStatus: DRAFT — Review and confirm in the Orders panel to push to Nhanh.vn."
    lines.join("\n")
  end

  def append_warnings(lines, warnings)
    return if warnings.blank?

    lines << "\nStock warnings:"
    warnings.each { |w| lines << " • #{w}" }
  end
end
