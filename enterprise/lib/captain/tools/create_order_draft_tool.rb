# Generic router tool: Create a draft order.
# Auto-delegates to the platform-specific create order draft tool based on
# the conversation inbox's e-commerce integration.
# Falls back to creating a local draft order using Shopiz built-in products.
class Captain::Tools::CreateOrderDraftTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::EcomRoutable
  include Captain::Tools::Concerns::OrderMessageSendable

  description 'Create a draft order with products for the current contact. ' \
              'The order is saved as a draft and order details are automatically sent to the customer. ' \
              'Do not send a separate message with order details.'

  param :product_identifiers, type: 'string', desc: 'Comma-separated product IDs or codes (e.g. "123,456")', required: true
  param :quantities, type: 'string', desc: 'Comma-separated quantities matching each product (e.g. "2,1")', required: true
  param :customer_note, type: 'string', desc: 'Optional note from the customer', required: false

  # KiotViet & Nhanh.vn use product_codes; all others use product_ids
  CODE_BASED_PLATFORMS = %w[kiotviet nhanhvn].freeze

  def perform(tool_context, product_identifiers:, quantities:, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    unless conversation.account.ai_allow_create_order
      return 'AI order creation is disabled for this account. Please ask an agent to create the order manually.'
    end

    platform = resolve_ecom_platform(tool_context)
    if platform
      args = build_platform_args(platform, product_identifiers, quantities, customer_note)
      result = delegate_to_ecom_tool(platform, tool_context, **args)
      return result if result
    end

    # Fallback to local DB
    log_tool_usage('create_order_draft', { product_identifiers: product_identifiers, quantities: quantities })
    create_local_draft_order(conversation, product_identifiers, quantities, customer_note)
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::KiotvietCreateOrderDraftTool',
      'sapo' => 'Captain::Tools::SapoCreateOrderDraftTool',
      'haravan' => 'Captain::Tools::HaravanCreateOrderDraftTool',
      'shopify' => 'Captain::Tools::ShopifyCreateOrderDraftTool',
      'woocommerce' => 'Captain::Tools::WoocommerceCreateOrderDraftTool',
      'nhanhvn' => 'Captain::Tools::NhanhvnCreateOrderDraftTool'
      # TikTok Shop does not support create_order_draft
    }.freeze
  end

  def build_platform_args(platform, identifiers, quantities, note)
    base = { quantities: quantities, customer_note: note }.compact
    if CODE_BASED_PLATFORMS.include?(platform)
      base.merge(product_codes: identifiers)
    else
      base.merge(product_ids: identifiers)
    end
  end

  def create_local_draft_order(conversation, product_identifiers, quantities, customer_note)
    contact = conversation.contact
    return 'Contact not found' unless contact

    ids = product_identifiers.split(',').map(&:strip).reject(&:blank?)
    qtys = parse_quantities(quantities, ids.size)
    return 'Product identifiers and quantities must match' if ids.size != qtys.size

    items_data = resolve_local_products(conversation.account, ids, qtys)
    return items_data[:error] if items_data[:error]

    order = build_and_save_local_order(conversation, contact, items_data[:items], customer_note)
    send_order_summary_message(conversation, order)
    format_draft_result(order, items_data)
  end

  def parse_quantities(str, expected_size)
    parsed = str.split(',').map { |q| q.strip.to_i }
    return Array.new(expected_size, parsed.first) if parsed.size == 1 && expected_size > 1

    parsed
  end

  def resolve_local_products(account, ids, qtys)
    items = []
    warnings = []

    ids.each_with_index do |id, idx|
      product = account.products.find_by(id: id) || account.products.find_by(sku: id)
      return { error: "Product '#{id}' not found in the store" } unless product

      stock = product.inventory_quantity.to_i
      qty = qtys[idx]
      warnings << "#{product.name} (ID: #{product.id}): only #{stock} in stock" if stock < qty

      items << {
        product_name: product.name,
        product_id: product.id.to_s,
        product_source: 'shopiz',
        quantity: qty,
        unit_price: product.price.to_f,
        product_thumbnail: product.images&.first
      }
    end
    { items: items, warnings: warnings }
  end

  def build_and_save_local_order(conversation, contact, items, customer_note)
    order = conversation.conversation_orders.new(
      account: conversation.account,
      contact: contact,
      status: :draft,
      customer_name: contact.name,
      customer_phone: contact.phone_number,
      customer_address: contact.additional_attributes&.dig('address'),
      customer_note: customer_note,
      external_source: 'shopiz'
    )

    items.each do |item|
      order.items.build(item.slice(:product_name, :product_id, :product_source, :quantity, :unit_price, :product_thumbnail))
    end

    order.save!
    order
  end

  def format_draft_result(order, items_data)
    lines = ["Draft order ##{order.id} created. Order details sent to customer.\n", 'Items:']
    items_data[:items].each do |i|
      lines << "  • #{i[:product_name]} × #{i[:quantity]} — #{i[:unit_price]} each"
    end
    lines << "\nTotal: #{order.total_amount}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"

    if items_data[:warnings].present?
      lines << "\n⚠️ Stock warnings:"
      items_data[:warnings].each { |w| lines << "  • #{w}" }
    end

    lines << "\nThis is a DRAFT order. Order summary has been sent to the customer."
    lines.join("\n")
  end
end
