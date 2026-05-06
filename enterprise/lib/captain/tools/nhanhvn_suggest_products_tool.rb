# Public tool: Suggest upsell/cross-sell products based on a Nhanh.vn product.
# Priority: 1) Conversation context  2) Frequently bought together  3) Same category
class Captain::Tools::NhanhvnSuggestProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::NhanhvnClient

  description 'Suggest upsell and cross-sell products based on the current product selection and conversation context. ' \
              'Returns complementary products, higher-tier alternatives, and popular items from the same category.'
  param :product_code, type: 'string', desc: 'Nhanh.vn product code to base suggestions on', required: true
  param :context, type: 'string', desc: 'Brief description of what the customer is looking for (extracted from conversation)', required: false

  def active?
    nhanhvn_active?
  end

  def perform(_tool_context, product_code:, context: nil)
    log_tool_usage('nhanhvn_suggest_products', { product_code: product_code })

    product = lookup_product_by_code(product_code)
    return "Product '#{product_code}' not found" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  private

  def lookup_product_by_code(code)
    result = nhanhvn_post('/api/product/search', { code: code, icpp: 1 })
    products_hash = result&.dig('data', 'products')
    return nil unless products_hash.is_a?(Hash)

    products_hash.values.first
  end

  def gather_suggestions(product)
    {
      companion: find_companion_products(product),
      upsell: find_upsell_products(product),
      same_category: find_category_products(product)
    }
  end

  # Strategy 1: Frequently bought together — scan recent orders
  def find_companion_products(product)
    result = nhanhvn_post('/api/order/index', { icpp: 10 })
    orders_hash = result&.dig('data', 'orders')
    return [] unless orders_hash.is_a?(Hash)

    companion_map = build_companion_map(orders_hash.values, product['idNhanh'].to_s)
    top_companions(companion_map)
  end

  def build_companion_map(orders, product_id)
    map = {}
    orders.each do |order|
      items = extract_order_items(order)
      next unless items.any? { |item| item['idNhanh'].to_s == product_id }

      collect_companions(items, product_id, map)
    end
    map
  end

  def extract_order_items(order)
    products = order['products']
    return [] if products.blank?

    products.is_a?(Hash) ? products.values : products
  end

  def collect_companions(items, product_id, map)
    items.each do |item|
      next if item['idNhanh'].to_s == product_id

      key = item['idNhanh'].to_s
      map[key] ||= { count: 0, name: item['productName'], price: item['price'] }
      map[key][:count] += 1
    end
  end

  def top_companions(map)
    map.sort_by { |_, v| -v[:count] }.first(3).map do |_id, info|
      { name: info[:name], price: info[:price], reason: "Bought together #{info[:count]} time(s)" }
    end
  end

  # Strategy 2: Same category, higher price (upsell)
  def find_upsell_products(product)
    return [] if product['categoryId'].blank?

    products = fetch_category_products(product['categoryId'])
    products
      .select { |p| p['idNhanh'].to_s != product['idNhanh'].to_s && p['price'].to_f > product['price'].to_f }
      .first(3)
      .map { |p| format_product_entry(p, product['price']) }
  end

  # Strategy 3: Same category alternatives
  def find_category_products(product)
    return [] if product['categoryId'].blank?

    products = fetch_category_products(product['categoryId'])
    products
      .reject { |p| p['idNhanh'].to_s == product['idNhanh'].to_s }
      .first(3)
      .map { |p| format_product_entry(p, nil) }
  end

  def fetch_category_products(category_id)
    result = nhanhvn_post('/api/product/search', { categoryId: category_id, icpp: 10 })
    products_hash = result&.dig('data', 'products')
    return [] unless products_hash.is_a?(Hash)

    products_hash.values
  end

  def format_product_entry(product, base_price)
    stock = compute_stock(product['inventory'])
    reason = base_price ? "Premium option (+#{format_vnd((product['price'].to_f - base_price.to_f).round)})" : 'Same category'
    { code: product['code'], name: product['name'], price: product['price'], stock: stock, reason: reason }
  end

  def compute_stock(inventory)
    available = inventory&.dig('available').to_i
    status = if available > 5
               'In Stock'
             else
               (available.positive? ? 'Low Stock' : 'Out of Stock')
             end
    { total: available, status: status }
  end

  def format_suggestions(product, suggestions, context)
    lines = ["Product: #{product['name']} (#{product['code']}) — #{format_vnd(product['price'])}\n"]
    lines << "Customer context: #{context}\n" if context.present?
    append_companion_section(lines, suggestions[:companion])
    append_upsell_section(lines, suggestions[:upsell])
    append_category_section(lines, suggestions[:same_category])
    lines << 'No product suggestions available at this time.' if suggestions.values.all?(&:blank?)
    lines.join("\n")
  end

  def append_companion_section(lines, companions)
    return if companions.blank?

    lines << '🔗 Frequently bought together:'
    companions.each { |s| lines << "  • #{s[:name]} — #{format_vnd(s[:price])} (#{s[:reason]})" }
  end

  def append_upsell_section(lines, upsells)
    return if upsells.blank?

    lines << "\n⬆️ Upsell options:"
    upsells.each { |s| lines << "  • #{s[:name]} (#{s[:code]}) — #{format_vnd(s[:price])} | Stock: #{s[:stock][:total]} (#{s[:reason]})" }
  end

  def append_category_section(lines, category_items)
    return if category_items.blank?

    lines << "\n📦 More from same category:"
    category_items.each { |s| lines << "  • #{s[:name]} (#{s[:code]}) — #{format_vnd(s[:price])} | Stock: #{s[:stock][:total]}" }
  end
end
