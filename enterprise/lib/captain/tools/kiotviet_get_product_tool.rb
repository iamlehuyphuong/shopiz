# Public tool: Search KiotViet products by name keyword.
# Uses the KiotViet Public API `name` filter on GET /products.
class Captain::Tools::KiotvietGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::KiotvietClient

  description 'Search KiotViet products by name or keyword to find product details, pricing, and stock availability'
  param :query, type: 'string', desc: 'Product name or keyword to search for', required: true

  def active?
    kiotviet_active?
  end

  def perform(_tool_context, query:)
    log_tool_usage('kiotviet_get_product', { query: query })

    products = fetch_products(query)
    return "No products found matching '#{query}'" if products.blank?

    format_products(products, query)
  end

  private

  def fetch_products(query)
    result = kiotviet_get('products', { name: query, pageSize: 20, includeInventory: true, isActive: true })
    result&.dig('data') || []
  end

  def format_products(products, query)
    header = "Found #{products.size} product(s) matching '#{query}':\n\n"
    body = products.first(10).map { |product| format_product(product) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    lines = build_product_lines(product)
    lines << "  Description: #{product['description'].truncate(200)}" if product['description'].present?
    lines.join("\n")
  end

  def build_product_lines(product)
    stock = compute_stock(product['inventories'])
    [
      product['fullName'] || product['name'],
      "  Code: #{product['code']}",
      "  Price: #{format_currency(product['basePrice'])}",
      "  Stock: #{stock[:total]} (#{stock[:status]})",
      product['categoryName'].present? ? "  Category: #{product['categoryName']}" : nil,
      product['unit'].present? ? "  Unit: #{product['unit']}" : nil
    ].compact
  end

  def compute_stock(inventories)
    total = inventories&.sum { |inv| inv['onHand'].to_f } || 0
    status = if total > 5
               'In Stock'
             elsif total.positive?
               'Low Stock'
             else
               'Out of Stock'
             end
    { total: total.to_i, status: status }
  end
end
