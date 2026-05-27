# Copilot tool: Search KiotViet products by name keyword or list all products with inventory.
class Captain::Tools::Copilot::KiotvietSearchProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_search_products'
  end

  description 'Search KiotViet products by name keyword, or list all products with stock and pricing information'
  param :query, type: :string, desc: 'Product name keyword to search for. Leave empty to list all products.', required: false
  param :category_id, type: :integer, desc: 'Filter by category ID', required: false

  def execute(query: nil, category_id: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    products = fetch_products(query, category_id)
    return "No products found#{query.present? ? "matching '#{query}'": ''}" if products.blank?

    total_count = products.size
    <<~RESPONSE
      #{total_count > 25 ? "Found #{total_count} products (showing first 25)": "Found #{total_count} product(s)"}
      #{products.first(25).map { |p| format_product(p) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def fetch_products(query, category_id)
    params = { pageSize: 50, includeInventory: true, isActive: true }
    params[:name] = query if query.present?
    params[:categoryId] = category_id if category_id.present?

    result = kiotviet_get('products', params)
    result&.dig('data') || []
  end

  def format_product(product)
    stock = compute_stock(product['inventories'])
    <<~PRODUCT.strip
      #{product['fullName'] || product['name']} (Code: #{product['code']})
      Price: #{format_vnd(product['basePrice'])} | Stock: #{stock[:total]} (#{stock[:status]})
      Category: #{product['categoryName'] || 'N/A'} | Unit: #{product['unit'] || 'N/A'}
    PRODUCT
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
