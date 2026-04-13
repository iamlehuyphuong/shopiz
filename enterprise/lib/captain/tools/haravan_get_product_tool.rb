# Public tool: Search Haravan products by name keyword.
class Captain::Tools::HaravanGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::HaravanClient

  description 'Search Haravan products by name or keyword to find product details, pricing, and stock availability'
  param :query, type: 'string', desc: 'Product name or keyword to search for', required: true

  def active?
    haravan_active?
  end

  def perform(_tool_context, query:)
    log_tool_usage('haravan_get_product', { query: query })

    products = fetch_products(query)
    return "No products found matching '#{query}'" if products.blank?

    format_products(products, query)
  end

  private

  def fetch_products(query)
    result = haravan_get('products.json', { title: query, limit: 20 })
    products = result&.dig('products') || []
    return products if products.present?

    fetch_products_by_filter(query)
  end

  def fetch_products_by_filter(query)
    result = haravan_get('products.json', { limit: 50 })
    (result&.dig('products') || []).select { |p| p['title']&.downcase&.include?(query.downcase) }
  end

  def format_products(products, query)
    header = "Found #{products.size} product(s) matching '#{query}':\n\n"
    body = products.first(10).map { |p| format_product(p) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    lines = build_product_lines(product)
    lines << "  Description: #{strip_html(product['body_html'])}" if product['body_html'].present?
    lines.join("\n")
  end

  def build_product_lines(product)
    stock = compute_stock(product['variants'])
    [
      product['title'].to_s,
      "  Price: #{compute_price_range(product['variants'])}",
      "  Stock: #{stock[:total]} (#{stock[:status]})",
      product['product_type'].present? ? "  Type: #{product['product_type']}" : nil
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
end
