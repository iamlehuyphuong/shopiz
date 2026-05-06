# Copilot tool: Suggest upsell/cross-sell products for agents.
# Priority: 1) Conversation context  2) Frequently bought together  3) Same category
class Captain::Tools::Copilot::KiotvietSuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_suggest_products'
  end

  description 'Suggest upsell and cross-sell products based on a KiotViet product. ' \
              'Returns frequently bought together items, premium alternatives, and same-category options.'
  param :product_code, type: :string, desc: 'KiotViet product code to base suggestions on', required: true
  param :strategy, type: :string, desc: 'Suggestion strategy: "upsell", "cross_sell", or "both" (default: "both")', required: false
  param :context, type: :string, desc: 'Customer needs context extracted from conversation', required: false

  def execute(product_code:, strategy: 'both', context: nil)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    product = lookup_product(product_code)
    return "Product '#{product_code}' not found on KiotViet" if product.nil?

    suggestions = gather_suggestions(product, strategy || 'both')
    format_response(product, suggestions, context)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def lookup_product(code)
    result = kiotviet_get('products/code', { code: code })
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def gather_suggestions(product, strategy)
    result = {}
    result[:companion] = find_companion_products(product['id']) if %w[cross_sell both].include?(strategy)
    result[:upsell] = find_upsell_products(product) if %w[upsell both].include?(strategy) && product['categoryId'].present?
    result[:alternatives] = find_category_alternatives(product) if product['categoryId'].present?
    result
  end

  # -- Companion products (frequently bought together) --

  def find_companion_products(product_id)
    invoices = fetch_recent_invoices
    companion_map = build_companion_map(invoices, product_id)
    top_companions(companion_map)
  end

  def fetch_recent_invoices
    result = kiotviet_get('invoices', { pageSize: 20, orderDirection: 'Desc' })
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

      map[d['productId']] ||= { count: 0, name: d['productName'], price: d['price'], code: d['productCode'] }
      map[d['productId']][:count] += 1
    end
  end

  def top_companions(map)
    map.sort_by { |_, v| -v[:count] }.first(5).map do |_id, info|
      { name: info[:name], code: info[:code], price: info[:price], reason: "Bought together #{info[:count]} time(s)" }
    end
  end

  # -- Upsell products (same category, higher price) --

  def find_upsell_products(product)
    products = fetch_category_products(product['categoryId'])
    products
      .select { |p| p['id'] != product['id'] && p['basePrice'].to_f > product['basePrice'].to_f }
      .sort_by { |p| p['basePrice'].to_f }
      .first(5)
      .map { |p| format_product_entry(p, product['basePrice']) }
  end

  # -- Category alternatives (same category, lower/equal price) --

  def find_category_alternatives(product)
    products = fetch_category_products(product['categoryId'])
    products
      .reject { |p| p['id'] == product['id'] }
      .select { |p| p['basePrice'].to_f <= product['basePrice'].to_f }
      .first(5)
      .map { |p| format_product_entry(p, nil) }
  end

  def fetch_category_products(category_id)
    result = kiotviet_get('products', { categoryId: category_id, pageSize: 20, includeInventory: true, isActive: true })
    result&.dig('data') || []
  end

  def format_product_entry(product, base_price)
    stock = compute_stock(product['inventories'])
    reason = base_price ? "Premium option (+#{format_vnd((product['basePrice'].to_f - base_price.to_f).round)})" : 'Same category alternative'
    { name: product['fullName'] || product['name'], code: product['code'], price: product['basePrice'], stock: stock[:total], reason: reason }
  end

  def compute_stock(inventories)
    total = inventories&.sum { |inv| inv['onHand'].to_f } || 0
    { total: total.to_i }
  end

  # -- Response formatting --

  def format_response(product, suggestions, context)
    sections = build_header_sections(product, context)
    append_suggestion_sections(sections, suggestions)
    sections << "\nNo suggestions available." if suggestions.values.all?(&:blank?)
    sections.join("\n")
  end

  def build_header_sections(product, context)
    sections = ["📦 Base product: #{product['fullName'] || product['name']} (#{product['code']}) — #{format_vnd(product['basePrice'])}"]
    sections << "🎯 Customer context: #{context}" if context.present?
    sections
  end

  def append_suggestion_sections(sections, suggestions)
    append_section(sections, suggestions[:companion], '🔗 Frequently bought together') { |s| format_companion_line(s) }
    append_section(sections, suggestions[:upsell], '⬆️ Upsell recommendations') { |s| format_upsell_line(s) }
    append_section(sections, suggestions[:alternatives], '🔄 Category alternatives') { |s| format_alt_line(s) }
  end

  def append_section(sections, items, title, &)
    return if items.blank?

    lines = items.map(&)
    sections << "\n#{title}:\n#{lines.join("\n")}"
  end

  def format_companion_line(suggestion)
    "  • #{suggestion[:name]} (#{suggestion[:code]}) — #{format_vnd(suggestion[:price])} | #{suggestion[:reason]}"
  end

  def format_upsell_line(suggestion)
    "  • #{suggestion[:name]} (#{suggestion[:code]}) — #{format_vnd(suggestion[:price])} | Stock: #{suggestion[:stock]} | #{suggestion[:reason]}"
  end

  def format_alt_line(suggestion)
    "  • #{suggestion[:name]} (#{suggestion[:code]}) — #{format_vnd(suggestion[:price])} | Stock: #{suggestion[:stock]}"
  end
end
