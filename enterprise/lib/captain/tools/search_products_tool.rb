class Captain::Tools::SearchProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::EcomRoutable

  description 'Search for products in the store by keyword, name, or SKU to help customers find what they want'

  param :query, type: 'string', desc: 'The search keyword, product name, or SKU'
  param :limit, type: 'integer', desc: 'Number of results to return (default: 5)', required: false

  def perform(tool_context, query:, limit: 5)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'Search query is required' if query.blank?

    # Route to ecom platform if inbox is linked
    platform = resolve_ecom_platform(tool_context)
    if platform
      result = delegate_to_ecom_tool(platform, tool_context, query: query)
      return result if result
    end

    # Fallback: search local DB
    limit = [limit.to_i, 10].min # Cap limit to 10
    limit = 5 if limit <= 0

    log_tool_usage('search_products', { conversation_id: conversation.id, query: query })

    conversation.account
    products = account_scoped(Product).where(status: :active)
                                      .where('name ILIKE :query OR sku ILIKE :query OR description ILIKE :query', query: "%#{query}%")
                                      .limit(limit)

    return "No products found matching '#{query}'" if products.empty?

    format_products(products)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to search products'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::KiotvietGetProductTool',
      'sapo' => 'Captain::Tools::SapoGetProductTool',
      'haravan' => 'Captain::Tools::HaravanGetProductTool',
      'shopify' => 'Captain::Tools::ShopifyGetProductTool',
      'woocommerce' => 'Captain::Tools::WoocommerceGetProductTool',
      'nhanhvn' => 'Captain::Tools::NhanhvnGetProductTool',
      'tiktok_shop' => 'Captain::Tools::TiktokShopGetProductTool'
    }.freeze
  end

  def format_products(products)
    results = products.map do |product|
      {
        id: product.id,
        name: product.name,
        sku: product.sku,
        price: format_price(product.price),
        status: product.status,
        has_variants: product.product_variants.exists?,
        description: format_description(product.description)
      }.compact
    end

    "Found #{results.size} products:\n#{results.to_json}"
  end

  def format_price(price)
    return 'N/A' if price.blank?

    price.to_f
  end

  def format_description(description)
    return nil if description.blank?

    description.truncate(150)
  end
end
