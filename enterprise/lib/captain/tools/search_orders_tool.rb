class Captain::Tools::SearchOrdersTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::EcomRoutable

  description 'Search for recent orders of the current customer or lookup a specific order by ID or phone number'

  param :order_id, type: 'string', desc: 'The specific order ID or display ID to look up', required: false
  param :phone_number, type: 'string', desc: 'The customer phone number to search for orders', required: false

  def perform(tool_context, order_id: nil, phone_number: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Route to ecom platform if inbox is linked
    platform = resolve_ecom_platform(tool_context)
    if platform
      # Most ecom search_orders tools accept no kwargs (they resolve contact
      # internally via tool_context). TikTok Shop is the exception — it requires order_id:.
      args = build_search_orders_args(platform, order_id, phone_number)
      result = delegate_to_ecom_tool(platform, tool_context, **args)
      return result if result
    end

    # Fallback: search local DB
    contact = find_contact(tool_context.state)

    log_tool_usage('search_orders', { conversation_id: conversation.id, contact_id: contact&.id, order_id: order_id })

    orders = fetch_orders(contact, order_id, phone_number)

    return 'No orders found for the provided criteria.' if orders.empty?

    format_orders(orders)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to search orders'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Kiotviet::SearchOrdersTool',
      'sapo' => 'Captain::Tools::Sapo::SearchOrdersTool',
      'haravan' => 'Captain::Tools::Haravan::SearchOrdersTool',
      'shopify' => 'Captain::Tools::Shopify::SearchOrdersTool',
      'woocommerce' => 'Captain::Tools::Woocommerce::SearchOrdersTool',
      'nhanhvn' => 'Captain::Tools::Nhanhvn::SearchOrdersTool',
      'tiktok_shop' => 'Captain::Tools::TiktokShop::SearchOrdersTool'
    }.freeze
  end

  # TikTok Shop requires order_id:; all other platforms accept no kwargs
  # (they resolve the contact internally from tool_context).
  KWARG_PLATFORMS = %w[tiktok_shop].freeze

  def build_search_orders_args(platform, order_id, _phone_number)
    return { order_id: order_id } if KWARG_PLATFORMS.include?(platform)

    {}
  end

  def fetch_orders(contact, order_id, phone_number)
    query = account_scoped(ConversationOrder).includes(:items).ordered

    if order_id.present?
      # Search by display_id or id depending on how the order ID is stored. Assuming it's the primary key id or a specific display field.
      query.where('id = ? OR display_id = ?', order_id_to_int(order_id), order_id).limit(1)
    elsif phone_number.present?
      # Try to find contact by phone number or query orders associated with a contact having that phone number
      contact_ids = account_scoped(Contact).where('phone_number LIKE ?', "%#{phone_number}%").pluck(:id)
      query.where(contact_id: contact_ids).limit(5)
    elsif contact.present?
      # Default: get recent orders for the current contact
      query.where(contact_id: contact.id).limit(5)
    else
      []
    end
  end

  def order_id_to_int(order_id)
    # Safely convert to integer for ID lookup, or return 0 if it's not a number
    order_id.to_s.match?(/\A\d+\z/) ? order_id.to_i : 0
  end

  def format_orders(orders)
    results = orders.map do |order|
      {
        id: order.id,
        display_id: order.display_id,
        status: order.status,
        payment_status: order.payment_status,
        total_amount: order.total_amount,
        shipping_fee: order.shipping_fee,
        tax: order.tax,
        discount_amount: order.discount_amount,
        created_at: order.created_at.iso8601,
        items: format_order_items(order.items)
      }.compact
    end

    "Found #{results.size} order(s):\n#{results.to_json}"
  end

  def format_order_items(items)
    items.map do |item|
      {
        name: item.name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: (item.quantity * item.unit_price)
      }.compact
    end
  end
end
