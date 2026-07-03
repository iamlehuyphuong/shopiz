# Public tool: Search TikTok Shop products for the AI agent.
class Captain::Tools::TiktokShopGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::TiktokShopClient

  description 'Search for products on TikTok Shop. Returns product name, price, status, and variants.'
  param :query, type: 'string', desc: 'Product name or keyword to search for'

  def active?
    tiktok_shop_active?
  end

  def perform(_tool_context, **args)
    arguments = args.stringify_keys
    return 'TikTok Shop integration is not active.' unless tiktok_shop_active?

    products = search_products(arguments['query'])
    return 'No products found on TikTok Shop.' if products.blank?

    format_products(products)
  end

  private

  def search_products(query)
    body = { page_size: 10 }
    body[:search_keyword] = query if query.present?

    result = tiktok_shop_post('/product/202309/products/search', body)
    result&.dig('data', 'products') || []
  end

  def format_products(products)
    header = "Found #{products.size} TikTok Shop product(s):\n\n"
    body = products.map { |p| format_product(p) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    lines = [
      "**#{product['title']}** (ID: #{product['id']})",
      "  Status: #{product['status']}"
    ]
    lines.concat(format_skus(product['skus']))
    lines << "  Image: #{product.dig('main_images', 0, 'url_list', 0)}" if product['main_images'].present?
    lines.join("\n")
  end

  def format_skus(skus)
    return [] if skus.blank?

    sku_info = skus.first(5).map { |sku| format_single_sku(sku) }
    result = ["  SKUs: #{sku_info.join(', ')}"]
    result << "  +#{skus.size - 5} more SKUs" if skus.size > 5
    result
  end

  def format_single_sku(sku)
    price = sku.dig('price', 'sale_price').to_f / 100.0
    stock = sku.dig('inventory', 0, 'quantity') || 'N/A'
    "#{sku['seller_sku'] || 'N/A'}: #{format_currency(price)} (Stock: #{stock})"
  end
end
