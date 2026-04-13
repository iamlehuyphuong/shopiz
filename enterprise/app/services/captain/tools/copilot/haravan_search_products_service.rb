# Copilot tool: Search Haravan products with inventory information.
class Captain::Tools::Copilot::HaravanSearchProductsService < Captain::Tools::Copilot::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def name
    'haravan_search_products'
  end

  def description
    'Search Haravan products by name or keyword to check pricing, inventory, and details'
  end

  def parameters
    [
      { name: 'query', type: 'string', description: 'Product name or keyword to search', required: true }
    ]
  end

  def active?
    haravan_active?
  end

  def execute(arguments)
    query = arguments['query']
    return 'Query is required' if query.blank?

    products = fetch_products(query)
    return "No Haravan products found for '#{query}'" if products.blank?

    format_result(products, query)
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

  def format_result(products, query)
    header = "Found #{products.size} Haravan product(s) for '#{query}':\n\n"
    body = products.first(10).map { |p| format_product(p) }.join("\n---\n")
    header + body
  end

  def format_product(product)
    stock = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
    [
      product['title'].to_s,
      "  Price: #{compute_price_range(product['variants'])}",
      "  Stock: #{stock}",
      product['product_type'].present? ? "  Type: #{product['product_type']}" : nil
    ].compact.join("\n")
  end

  def compute_price_range(variants)
    prices = variants&.map { |v| v['price'].to_f }&.uniq || []
    return '0' if prices.empty?

    prices.size > 1 ? "#{prices.min} - #{prices.max}" : prices.first.to_s
  end
end
