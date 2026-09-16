class Captain::Tools::SearchProductsTool < Captain::Tools::BasePublicTool
  description 'Search for products in the store by keyword, name, or SKU. ' \
              'Returns product data for internal use. ' \
              'After finding relevant products, use send_product_info tool to send details to the customer.'

  param :query, type: 'string', desc: 'The search keyword, product name, or SKU'
  param :limit, type: 'integer', desc: 'Number of results to return (default: 5)', required: false

  def perform(tool_context, query:, limit: 5)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'Search query is required' if query.blank?

    limit = [limit.to_i, 10].min # Cap limit to 10
    limit = 5 if limit <= 0

    log_tool_usage('search_products', { conversation_id: conversation.id, query: query })
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

  def format_products(products)
    results = products.map do |product|
      {
        id: product.id,
        name: product.name,
        sku: product.sku,
        price: format_price(product.price),
        status: product.status,
        inventory_quantity: product.inventory_quantity.to_i,
        has_images: product.images.present?,
        has_variants: product.product_variants.exists?,
        description: format_description(product.description)
      }.compact
    end

    "Found #{results.size} products. Use send_product_info with product IDs to share with customer.\n#{results.to_json}"
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
