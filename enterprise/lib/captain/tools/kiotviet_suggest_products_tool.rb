# Public tool: Suggest upsell/cross-sell products based on a KiotViet product.
# Priority: 1) Conversation context  2) Frequently bought together  3) Same category
class Captain::Tools::KiotvietSuggestProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::KiotvietClient

  description 'Suggest upsell and cross-sell products based on the current product selection and conversation context. ' \
              'Returns complementary products, higher-tier alternatives, and popular items from the same category.'
  param :product_code, type: 'string', desc: 'KiotViet product code to base suggestions on', required: true
  param :context, type: 'string', desc: 'Brief description of what the customer is looking for (extracted from conversation)', required: false

  def active?
    kiotviet_active?
  end

  def perform(_tool_context, product_code:, context: nil)
    log_tool_usage('kiotviet_suggest_products', { product_code: product_code })

    product = lookup_product_by_code(product_code)
    return "Product '#{product_code}' not found" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  private

  def lookup_product_by_code(code)
    result = kiotviet_get('products/code', { code: code })
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def gather_suggestions(product)
    {
      companion: find_companion_products(product['id']),
      upsell: product['categoryId'].present? ? find_upsell_products(product) : [],
      same_category: product['categoryId'].present? ? find_category_products(product) : []
    }
  end

  def find_companion_products(product_id)
    invoices = fetch_recent_invoices
    companion_map = build_companion_map(invoices, product_id)
    top_companions(companion_map)
  end

  def fetch_recent_invoices
    result = kiotviet_get('invoices', { pageSize: 10, orderDirection: 'Desc' })
    result&.dig('data') || []
  end

  def build_companion_map(invoices, product_id)
    map = {}
    invoices.each do |inv|
      details = inv['invoiceDetails'] || []
      next unless details.any? { |d| d['productId'] == product_id }

      collect_companions(details, product_id, map)
    end
    map
  end

  def collect_companions(details, product_id, map)
    details.each do |d|
      next if d['productId'] == product_id

      map[d['productId']] ||= { count: 0, name: d['productName'], price: d['price'] }
      map[d['productId']][:count] += 1
    end
  end

  def top_companions(map)
    map.sort_by { |_, v| -v[:count] }.first(3).map do |id, info|
      { id: id, name: info[:name], price: info[:price], reason: "Bought together #{info[:count]} time(s)" }
    end
  end

  def find_upsell_products(product)
    products = fetch_category_products(product['categoryId'])
    products
      .select { |p| p['id'] != product['id'] && p['basePrice'].to_f > product['basePrice'].to_f }
      .first(3)
      .map { |p| format_product_suggestion(p, product['basePrice']) }
  end

  def find_category_products(product)
    products = fetch_category_products(product['categoryId'])
    products
      .reject { |p| p['id'] == product['id'] }
      .first(3)
      .map { |p| format_product_suggestion(p, nil) }
  end

  def fetch_category_products(category_id)
    result = kiotviet_get('products', { categoryId: category_id, pageSize: 10, includeInventory: true, isActive: true })
    result&.dig('data') || []
  end

  def format_product_suggestion(product, base_price)
    stock = compute_stock(product['inventories'])
    reason = base_price ? "Premium option (+#{format_currency((product['basePrice'].to_f - base_price.to_f).round)})" : 'Same category'
    { id: product['id'], code: product['code'], name: product['fullName'] || product['name'],
      price: product['basePrice'], stock: stock, reason: reason }
  end

  def compute_stock(inventories)
    total = inventories&.sum { |inv| inv['onHand'].to_f } || 0
    status = if total > 5
               'In Stock'
             else
               (total.positive? ? 'Low Stock' : 'Out of Stock')
             end
    { total: total.to_i, status: status }
  end

  def format_suggestions(product, suggestions, context)
    lines = ["Product: #{product['fullName'] || product['name']} (#{product['code']}) — #{format_currency(product['basePrice'])}\n"]
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
    companions.each { |s| lines << "  • #{s[:name]} — #{format_currency(s[:price])} (#{s[:reason]})" }
  end

  def append_upsell_section(lines, upsells)
    return if upsells.blank?

    lines << "\n⬆️ Upsell options:"
    upsells.each { |s| lines << "  • #{s[:name]} (#{s[:code]}) — #{format_currency(s[:price])} | Stock: #{s[:stock][:total]} (#{s[:reason]})" }
  end

  def append_category_section(lines, category_items)
    return if category_items.blank?

    lines << "\n📦 More from same category:"
    category_items.each { |s| lines << "  • #{s[:name]} (#{s[:code]}) — #{format_currency(s[:price])} | Stock: #{s[:stock][:total]}" }
  end
end
