# Copilot tool: Search WooCommerce products with stock information.
class Captain::Tools::Copilot::WoocommerceSearchProductsService < Captain::Tools::Copilot::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient

  def name
    'woocommerce_search_products'
  end

  def description
    'Search WooCommerce products by name or keyword to check pricing, inventory, and details'
  end

  def parameters
    [
      { name: 'query', type: 'string', description: 'Product name or keyword to search', required: true }
    ]
  end

  def active?
    woocommerce_active?
  end

  def execute(arguments)
    query = arguments['query']
    return 'Query is required' if query.blank?

    products = fetch_products(query)
    return "No WooCommerce products found for '#{query}'" if products.blank?

    format_result(products, query)
  end

  private

  def fetch_products(query)
    result = woocommerce_get('products', { search: query, per_page: 20, status: 'publish' })
    result.is_a?(Array) ? result : []
  end

  def format_result(products, query)
    header = "Found #{products.size} WooCommerce product(s) for '#{query}':\n\n"
    body = products.first(10).map { |p| format_product(p) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    [
      product['name'].to_s,
      "  Price: #{product['price'] || '0'}",
      "  Regular: #{product['regular_price'] || '0'}",
      product['sale_price'].present? ? "  Sale: #{product['sale_price']}" : nil,
      "  Stock: #{product['stock_quantity'] || 0} (#{product['stock_status']})",
      product['categories'].present? ? "  Category: #{product['categories'].pluck('name').join(', ')}" : nil
    ].compact.join("\n")
  end
end
