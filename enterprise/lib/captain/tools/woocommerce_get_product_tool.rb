# Public tool: Search WooCommerce products by name keyword.
class Captain::Tools::WoocommerceGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::WoocommerceClient

  description 'Search WooCommerce products by name or keyword to find product details, pricing, and stock'
  param :query, type: 'string', desc: 'Product name or keyword to search for', required: true

  def active?
    woocommerce_active?
  end

  def perform(_tool_context, query:)
    log_tool_usage('woocommerce_get_product', { query: query })

    products = fetch_products(query)
    return "No products found matching '#{query}'" if products.blank?

    format_products(products, query)
  end

  private

  def fetch_products(query)
    result = woocommerce_get('products', { search: query, per_page: 20, status: 'publish' })
    result.is_a?(Array) ? result : []
  end

  def format_products(products, query)
    header = "Found #{products.size} product(s) matching '#{query}':\n\n"
    body = products.first(10).map { |p| format_product(p) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    lines = build_product_lines(product)
    lines << "  Description: #{strip_html(product['short_description'])}" if product['short_description'].present?
    lines.join("\n")
  end

  def build_product_lines(product)
    [
      product['name'].to_s,
      "  Price: #{product['price'] || '0'} #{product['currency'] || ''}",
      "  Stock: #{product['stock_quantity'] || 0} (#{product['stock_status']})",
      product['categories'].present? ? "  Category: #{product['categories'].pluck('name').join(', ')}" : nil
    ].compact
  end

  def strip_html(html)
    html&.gsub(/<[^>]*>/, '')&.strip&.truncate(200)
  end
end
