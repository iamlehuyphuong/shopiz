# Base class for platform-specific "Create Order" copilot tools.
# Subclasses only need to implement:
#   - platform_name      (e.g. 'kiotviet')
#   - platform_active?   (check integration status)
#   - resolve_product(identifier) -> Hash or nil
#   - extract_price(product) -> Float
#   - extract_stock(product) -> { total: Integer, status: String }
#   - extract_product_name(product) -> String
#   - extract_thumbnail(product) -> String or nil
#   - format_currency(amount) -> String
class Captain::Tools::Copilot::BaseCreateOrderService < Captain::Tools::BaseTool
  param :conversation_id, type: :integer, desc: 'Conversation display ID to attach the order to', required: true
  param :product_items, type: :string, desc: 'JSON array of items: [{"id":"SP001","qty":2}]', required: true
  param :customer_name, type: :string, desc: 'Customer name (auto-filled from contact if blank)', required: false
  param :customer_phone, type: :string, desc: 'Customer phone (auto-filled from contact if blank)', required: false
  param :delivery_address, type: :string, desc: 'Delivery address', required: false
  param :note, type: :string, desc: 'Order note', required: false

  # rubocop:disable Metrics/ParameterLists
  def execute(conversation_id:, product_items:, customer_name: nil, customer_phone: nil, delivery_address: nil, note: nil)
    return "#{platform_label} integration is not connected" unless platform_active?

    conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless conversation

    items = parse_product_items(product_items)
    return 'Invalid product_items format. Expected JSON array.' if items.nil?

    resolved = resolve_all_products(items)
    return resolved[:error] if resolved[:error]

    order = build_draft_order(conversation, resolved[:items],
                              customer_name: customer_name, customer_phone: customer_phone,
                              delivery_address: delivery_address, note: note)
    format_order_result(order, resolved)
  end
  # rubocop:enable Metrics/ParameterLists

  def active?
    @user.present? && platform_active?
  end

  private

  # --- Subclass hooks (must override) ---

  def platform_name
    raise NotImplementedError
  end

  def platform_label
    platform_name.titleize
  end

  def platform_active?
    raise NotImplementedError
  end

  def resolve_product(_identifier)
    raise NotImplementedError
  end

  def extract_price(_product)
    raise NotImplementedError
  end

  def extract_stock(_product)
    raise NotImplementedError
  end

  def extract_product_name(_product)
    raise NotImplementedError
  end

  def extract_thumbnail(_product)
    nil
  end

  def format_currency(_amount)
    raise NotImplementedError
  end

  # --- Shared helpers ---

  def stock_status(total, threshold: 5)
    return 'In Stock' if total > threshold
    return 'Low Stock' if total.positive?

    'Out of Stock'
  end

  # --- Shared logic ---

  def product_identifier_key
    'id'
  end

  def find_conversation(display_id)
    Conversation.find_by(account_id: @assistant.account_id, display_id: display_id)
  end

  def parse_product_items(raw)
    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
    key = product_identifier_key
    return nil unless parsed.is_a?(Array) && parsed.all? { |i| i[key].present? }

    parsed.map { |i| { identifier: i[key], qty: (i['qty'] || i['quantity'] || 1).to_i } }
  rescue JSON::ParserError
    nil
  end

  def resolve_all_products(items)
    resolved = []
    warnings = []

    items.each do |item|
      product = resolve_product(item[:identifier])
      return { error: "Product '#{item[:identifier]}' not found on #{platform_label}" } if product.nil?

      stock = extract_stock(product)
      warnings << "#{extract_product_name(product)}: only #{stock[:total]} in stock, requested #{item[:qty]}" if stock[:total] < item[:qty]

      resolved << {
        product_name: extract_product_name(product),
        product_id: item[:identifier].to_s,
        product_source: platform_name,
        quantity: item[:qty],
        unit_price: extract_price(product),
        product_thumbnail: extract_thumbnail(product),
        stock: stock
      }
    end

    { items: resolved, warnings: warnings }
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
      order.items.build(item.slice(:product_name, :product_id, :product_source, :quantity, :unit_price, :product_thumbnail))
    end

    order.save!
    order
  end

  def format_order_result(order, resolved)
    lines = ["✅ Draft order ##{order.id} created for conversation ##{order.conversation.display_id}\n"]
    resolved[:items].each { |item| lines << "  • #{item[:product_name]} × #{item[:quantity]} — #{format_currency(item[:unit_price])}" }
    lines << "\nTotal: #{format_currency(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    lines << "Address: #{order.customer_address}" if order.customer_address.present?

    if resolved[:warnings].present?
      lines << "\n⚠️ Stock warnings:"
      resolved[:warnings].each { |w| lines << "  • #{w}" }
    end

    lines << "\n📋 Status: DRAFT — Review and confirm in the Orders panel to push to #{platform_label}."
    lines.join("\n")
  end
end
