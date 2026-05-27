class Captain::Tools::Copilot::ShopifySearchProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::ShopifyClient

  def self.name
    'shopify_search_products'
  end

  description 'Search Shopify products by title keyword, or list all products with stock information'
  param :query, type: :string, desc: 'Product title keyword to search for. Leave empty to list all products.', required: false

  def execute(query: nil)
    return 'Shopify integration is not connected' unless shopify_active?

    products = fetch_products(query)
    return "No products found#{query.present? ? "matching '#{query}'": ''}" if products.blank?

    total_count = products.size
    <<~RESPONSE
      #{total_count > 25 ? "Found #{total_count} products (showing first 25)": "Found #{total_count} product(s)"}
      #{products.first(25).map { |p| format_product(p) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def fetch_products(query)
    params = { limit: 50 }
    params[:title] = query if query.present?

    result = shopify_get('products.json', params)
    products = result&.dig('products') || []
    return products if products.present? || query.blank?

    fetch_and_filter_locally(query)
  end

  def fetch_and_filter_locally(query)
    result = shopify_get('products.json', { limit: 50 })
    (result&.dig('products') || []).select { |p| p['title']&.downcase&.include?(query.downcase) }
  end

  def format_product(product)
    stock_info = compute_stock(product['variants'])
    price_display = compute_price_range(product['variants'])
    variants = extract_variant_names(product['variants'])

    <<~PRODUCT.strip
      #{product['title']} (ID: #{product['id']})
      Price: #{price_display} | Stock: #{stock_info[:total]} (#{stock_info[:status]})
      Type: #{product['product_type'].presence || 'N/A'} | Tags: #{product['tags'].presence || 'N/A'}
      #{"Variants: #{variants.join(', ')}" if variants.any?}
    PRODUCT
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

    prices.uniq.size > 1 ? "#{prices.min} - #{prices.max}": prices.first.to_s
  end

  def extract_variant_names(variants)
    (variants || []).map { |v| v['title'] }.reject { |t| t == 'Default Title' }
  end
end
