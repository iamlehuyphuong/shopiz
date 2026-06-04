# Copilot tool: Search Nhanh.vn products by name keyword or list all products with inventory.
class Captain::Tools::Copilot::NhanhvnSearchProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_search_products'
  end

  description 'Search Nhanh.vn products by name keyword, or list all products with stock and pricing information'
  param :query, type: :string, desc: 'Product name keyword to search for. Leave empty to list all products.', required: false

  def execute(query: nil)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    products = fetch_products(query)
    return "No products found#{query.present? ? " matching '#{query}'" : ''}" if products.blank?

    total_count = products.size
    <<~RESPONSE
      #{total_count > 25 ? "Found #{total_count} products (showing first 25)" : "Found #{total_count} product(s)"}
      #{products.first(25).map { |p| format_product(p) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def fetch_products(query)
    data = { icpp: 50 }
    data[:name] = query if query.present?

    result = nhanhvn_post('/api/product/search', data)
    products_hash = result&.dig('data', 'products')
    return [] unless products_hash.is_a?(Hash)

    products_hash.values
  end

  def format_product(product)
    stock = compute_stock(product['inventory'])
    <<~PRODUCT.strip
      #{product['name']} (Code: #{product['code']})
      Price: #{format_vnd(product['price'])} | Stock: #{stock[:total]} (#{stock[:status]})
      Brand: #{product['brandName'] || 'N/A'} | Status: #{product['status'] || 'N/A'}
    PRODUCT
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
