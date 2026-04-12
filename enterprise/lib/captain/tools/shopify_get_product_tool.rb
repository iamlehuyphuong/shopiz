class Captain::Tools::ShopifyGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::ShopifyClient

  description 'Search Shopify products by name or keyword to find product details, pricing, and stock availability'
  param :query, type: 'string', desc: 'Product name or keyword to search for', required: true

  def active?
    shopify_active?
  end

  def perform(_tool_context, query:)
    log_tool_usage('shopify_get_product', { query: query })

    products = fetch_products(query)
    return "No products found matching '#{query}'" if products.blank?

    format_products(products, query)
  end

  private

  def fetch_products(query)
    result = shopify_get('products.json', { title: query, limit: 10 })
    products = result&.dig('products') || []
    return products if products.present?

    fetch_and_filter_locally(query)
  end

  def fetch_and_filter_locally(query)
    result = shopify_get('products.json', { limit: 50 })
    (result&.dig('products') || []).select { |p| p['title']&.downcase&.include?(query.downcase) }
  end

  def format_products(products, query)
    header = "Found #{products.size} product(s) matching '#{query}':\n\n"
    body = products.first(10).map { |product| format_product(product) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    lines = build_product_lines(product)
    lines << "  Description: #{strip_html(product['body_html'])}" if product['body_html'].present?
    append_variants(lines, product['variants'])
    lines.join("\n")
  end

  def build_product_lines(product)
    stock_info = compute_stock(product['variants'])
    [
      product['title'].to_s,
      "  Price: #{compute_price_range(product['variants'])}",
      "  Stock: #{stock_info[:total]} (#{stock_info[:status]})",
      product['product_type'].present? ? "  Type: #{product['product_type']}" : nil,
      product['tags'].present? ? "  Tags: #{product['tags']}" : nil
    ].compact
  end

  def compute_stock(variants)
    total = variants&.sum { |v| v['inventory_quantity'].to_i } || 0
    status = if total > 5
               'In Stock'
             elsif total.positive?
               'Low Stock'
             else
               'Out of Stock'
             end
    { total: total, status: status }
  end

  def compute_price_range(variants)
    prices = variants&.map { |v| v['price'].to_f } || []
    return '0' if prices.empty?

    prices.uniq.size > 1 ? "#{prices.min} - #{prices.max}" : prices.first.to_s
  end

  def strip_html(html)
    html&.gsub(/<[^>]*>/, '')&.strip&.truncate(200)
  end

  def append_variants(lines, variants)
    return if variants.blank?

    names = variants.map { |v| v['title'] }.reject { |t| t == 'Default Title' }
    lines << "  Variants: #{names.join(', ')}" if names.any?
  end
end
