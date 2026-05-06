# Public tool: Suggest upsell/cross-sell products from Sapo.
class Captain::Tools::SapoSuggestProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::SapoClient

  description 'Suggest upsell and cross-sell products based on the current product selection. ' \
              'Returns complementary products, higher-tier alternatives, and popular items.'
  param :product_id, type: 'string', desc: 'Sapo product ID to base suggestions on', required: true
  param :context, type: 'string', desc: 'What the customer is looking for', required: false

  def active?
    sapo_active?
  end

  def perform(_tool_context, product_id:, context: nil)
    log_tool_usage('sapo_suggest_products', { product_id: product_id })

    product = fetch_product(product_id)
    return "Product ID '#{product_id}' not found" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  private

  def fetch_product(id)
    result = sapo_get("products/#{id}.json")
    result&.dig('product')
  end

  def gather_suggestions(product)
    {
      upsell: find_upsell_products(product),
      same_type: find_same_type_products(product)
    }
  end

  def find_upsell_products(product)
    return [] if product['product_type'].blank?

    products = fetch_products_by_type(product['product_type'])
    base_price = product['variants']&.first&.dig('price').to_f
    products
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .select { |p| p['variants']&.first&.dig('price').to_f > base_price }
      .first(3)
      .map { |p| format_entry(p, "Premium (+#{format_sapo_currency((p['variants']&.first&.dig('price').to_f - base_price).round)})") }
  end

  def find_same_type_products(product)
    return [] if product['product_type'].blank?

    products = fetch_products_by_type(product['product_type'])
    products
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .first(3)
      .map { |p| format_entry(p, 'Same type') }
  end

  def fetch_products_by_type(product_type)
    result = sapo_get('products.json', { product_type: product_type, limit: 10 })
    result&.dig('products') || []
  end

  def format_entry(product, reason)
    stock = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
    price = product['variants']&.first&.dig('price').to_f
    { name: product['name'], price: price, stock: stock, reason: reason }
  end

  def format_suggestions(product, suggestions, context)
    price = product['variants']&.first&.dig('price').to_f
    lines = ["Product: #{product['name']} (ID: #{product['id']}) — #{format_sapo_currency(price)}\n"]
    lines << "Customer context: #{context}\n" if context.present?
    append_upsell_section(lines, suggestions[:upsell])
    append_type_section(lines, suggestions[:same_type])
    lines << 'No product suggestions available at this time.' if suggestions.values.all?(&:blank?)
    lines.join("\n")
  end

  def append_upsell_section(lines, upsells)
    return if upsells.blank?

    lines << '⬆️ Upsell options:'
    upsells.each { |s| lines << "  • #{s[:name]} — #{format_sapo_currency(s[:price])} | Stock: #{s[:stock]} (#{s[:reason]})" }
  end

  def append_type_section(lines, items)
    return if items.blank?

    lines << "\n📦 More from same type:"
    items.each { |s| lines << "  • #{s[:name]} — #{format_sapo_currency(s[:price])} | Stock: #{s[:stock]}" }
  end
end
