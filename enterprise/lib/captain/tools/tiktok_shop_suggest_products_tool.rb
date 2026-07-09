# Public tool: Suggest upsell/cross-sell products from TikTok Shop.
class Captain::Tools::TiktokShopSuggestProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::TiktokShopClient

  description 'Suggest products based on the current product selection or context on TikTok Shop. ' \
              'Returns related products or popular items.'
  param :product_id, type: 'string', desc: 'TikTok Shop product ID to base suggestions on', required: false
  param :context, type: 'string', desc: 'What the customer is looking for (search keyword)', required: false

  def active?
    tiktok_shop_active?
  end

  def perform(_tool_context, product_id: nil, context: nil)
    log_tool_usage('tiktok_shop_suggest_products', { product_id: product_id, context: context })

    if product_id.present?
      product = fetch_product(product_id)
      return "Product ID '#{product_id}' not found" if product.nil?
    else
      product = nil
    end

    suggestions = gather_suggestions(product, context)
    format_suggestions(product, suggestions, context)
  end

  private

  def fetch_product(id)
    result = tiktok_shop_get("/product/202309/products/#{id}")
    result&.dig('data')
  end

  def gather_suggestions(product, context)
    {
      related: find_related_products(product, context)
    }
  end

  def find_related_products(product, context)
    query = context.presence || product&.dig('title')&.split&.first || ''

    products = search_products(query)

    products = products.reject { |p| p['id'].to_s == product['id'].to_s } if product.present?

    products.first(5).map { |p| format_entry(p) }
  end

  def search_products(query)
    body = { page_size: 10 }
    body[:title] = query if query.present?

    result = tiktok_shop_post('/product/202309/products/search', body)
    result&.dig('data', 'products') || []
  end

  def format_entry(product)
    stock = product['skus']&.sum { |v| v.dig('inventory', 'quantity').to_i } || 0
    price = product['skus']&.first&.dig('price', 'sale_price').to_f
    currency = product['skus']&.first&.dig('price', 'currency') || 'VND'

    { name: product['title'], price: price, currency: currency, stock: stock }
  end

  def format_suggestions(product, suggestions, context)
    lines = []
    if product.present?
      price = product['skus']&.first&.dig('price', 'sale_price').to_f
      currency = product['skus']&.first&.dig('price', 'currency') || 'VND'
      lines << "Base Product: #{product['title']} (ID: #{product['id']}) — #{format_currency(price, currency)}\n"
    end

    lines << "Customer context: #{context}\n" if context.present?

    if suggestions[:related].present?
      lines << '🛍️ Suggested products:'
      suggestions[:related].each do |s|
        lines << "  • #{s[:name]} — #{format_currency(s[:price], s[:currency])} | Stock: #{s[:stock]}"
      end
    else
      lines << 'No product suggestions available at this time.'
    end

    lines.join("\n")
  end
end
