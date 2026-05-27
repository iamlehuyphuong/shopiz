# Copilot tool: Suggest upsell/cross-sell products from Nhanh.vn.
# Priority: 1) Conversation context 2) Frequently bought together 3) Category alternatives
class Captain::Tools::Copilot::NhanhvnSuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_suggest_products'
  end

  description 'Suggest upsell and cross-sell products based on a Nhanh.vn product. ' \
              'Returns companion products, higher-tier alternatives, and same-category items.'
  param :product_code, type: :string, desc: 'Nhanh.vn product code to base suggestions on', required: true
  param :strategy, type: :string, desc: 'Suggestion strategy: companion, upsell, category, or both (default)', required: false
  param :context, type: :string, desc: 'Customer context from conversation', required: false

  def execute(product_code:, strategy: 'both', context: nil)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    product = lookup_product(product_code)
    return "Product '#{product_code}' not found on Nhanh.vn" if product.nil?

    suggestions = gather_suggestions(product, strategy)
    format_suggestions(product, suggestions, context)
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def lookup_product(code)
    result = nhanhvn_post('/api/product/search', { code: code, icpp: 1 })
    products_hash = result&.dig('data', 'products')
    return nil unless products_hash.is_a?(Hash)

    products_hash.values.first
  end

  def gather_suggestions(product, strategy)
    {
      companion: %w[both companion].include?(strategy) ? find_companions(product) : [],
      upsell: %w[both upsell].include?(strategy) ? find_upsells(product) : [],
      category: %w[both category].include?(strategy) ? find_category_items(product) : []
    }
  end

  def find_companions(product)
    result = nhanhvn_post('/api/order/index', { icpp: 10 })
    orders = result&.dig('data', 'orders')
    return [] unless orders.is_a?(Hash)

    companion_map = {}
    orders.each_value { |order| tally_companions(order, product['idNhanh'].to_s, companion_map) }
    companion_map.sort_by { |_, v| -v[:count] }.first(3).map { |_, v| v }
  end

  def tally_companions(order, product_id, map)
    items_array = parse_order_products(order)
    return unless items_array&.any? { |i| i['idNhanh'].to_s == product_id }

    record_companions(items_array, product_id, map)
  end

  def parse_order_products(order)
    items = order['products']
    return nil if items.blank?

    items.is_a?(Hash) ? items.values : items
  end

  def record_companions(items_array, product_id, map)
    items_array.each do |item|
      next if item['idNhanh'].to_s == product_id

      key = item['idNhanh'].to_s
      map[key] ||= { name: item['productName'], price: item['price'], count: 0 }
      map[key][:count] += 1
    end
  end

  def find_upsells(product)
    return [] if product['categoryId'].blank?

    products = fetch_category_products(product['categoryId'])
    products
      .select { |p| p['idNhanh'].to_s != product['idNhanh'].to_s && p['price'].to_f > product['price'].to_f }
      .first(3)
      .map { |p| format_entry(p, "Premium option (+#{format_vnd((p['price'].to_f - product['price'].to_f).round)})") }
  end

  def find_category_items(product)
    return [] if product['categoryId'].blank?

    products = fetch_category_products(product['categoryId'])
    products
      .reject { |p| p['idNhanh'].to_s == product['idNhanh'].to_s }
      .first(3)
      .map { |p| format_entry(p, 'Same category') }
  end

  def fetch_category_products(category_id)
    result = nhanhvn_post('/api/product/search', { categoryId: category_id, icpp: 10 })
    products_hash = result&.dig('data', 'products')
    return [] unless products_hash.is_a?(Hash)

    products_hash.values
  end

  def format_entry(product, reason)
    stock = product.dig('inventory', 'available').to_i
    { code: product['code'], name: product['name'], price: product['price'], stock: stock, reason: reason }
  end

  def format_suggestions(product, suggestions, context)
    lines = ["Base product: #{product['name']} (#{product['code']}) — #{format_vnd(product['price'])}"]
    lines << "Customer context: #{context}" if context.present?
    append_companion_lines(lines, suggestions[:companion])
    append_upsell_lines(lines, suggestions[:upsell])
    append_category_lines(lines, suggestions[:category])
    lines << 'No suggestions available.' if suggestions.values.all?(&:blank?)
    lines.join("\n")
  end

  def append_companion_lines(lines, companions)
    return if companions.blank?

    lines << "\n🔗 Frequently bought together:"
    companions.each { |s| lines << " • #{s[:name]} — #{format_vnd(s[:price])} | Bought together #{s[:count]} time(s)" }
  end

  def append_upsell_lines(lines, upsells)
    return if upsells.blank?

    lines << "\nUpsell recommendations:"
    upsells.each { |s| lines << " • #{s[:name]} (#{s[:code]}) — #{format_vnd(s[:price])} | Stock: #{s[:stock]} | #{s[:reason]}" }
  end

  def append_category_lines(lines, items)
    return if items.blank?

    lines << "\nCategory alternatives:"
    items.each { |s| lines << " • #{s[:name]} (#{s[:code]}) — #{format_vnd(s[:price])} | Stock: #{s[:stock]}" }
  end
end
