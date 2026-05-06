# Public tool: Search Nhanh.vn products by name keyword.
# Uses the Nhanh.vn API POST /api/product/search with `name` filter.
class Captain::Tools::NhanhvnGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::NhanhvnClient

  description 'Search Nhanh.vn products by name or keyword to find product details, pricing, and stock availability'
  param :query, type: 'string', desc: 'Product name or keyword to search for', required: true

  def active?
    nhanhvn_active?
  end

  def perform(_tool_context, query:)
    log_tool_usage('nhanhvn_get_product', { query: query })

    products = fetch_products(query)
    return "No products found matching '#{query}'" if products.blank?

    format_products(products, query)
  end

  private

  def fetch_products(query)
    result = nhanhvn_post('/api/product/search', { name: query, icpp: 20 })
    products_hash = result&.dig('data', 'products')
    return [] unless products_hash.is_a?(Hash)

    products_hash.values
  end

  def format_products(products, query)
    header = "Found #{products.size} product(s) matching '#{query}':\n\n"
    body = products.first(10).map { |product| format_product(product) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    lines = build_product_lines(product)
    lines.join("\n")
  end

  def build_product_lines(product)
    stock = compute_stock(product['inventory'])
    [
      product['name'],
      "  Code: #{product['code']}",
      "  Price: #{format_vnd(product['price'])}",
      "  Stock: #{stock[:total]} (#{stock[:status]})",
      product['brandName'].present? ? "  Brand: #{product['brandName']}" : nil,
      product['status'].present? ? "  Status: #{product['status']}" : nil
    ].compact
  end

  def compute_stock(inventory)
    available = inventory&.dig('available').to_i
    status = if available > 5
               'In Stock'
             elsif available.positive?
               'Low Stock'
             else
               'Out of Stock'
             end
    { total: available, status: status }
  end
end
