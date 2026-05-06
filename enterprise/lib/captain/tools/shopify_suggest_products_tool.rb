# Public tool: Suggest upsell/cross-sell products from Shopify.
class Captain::Tools::ShopifySuggestProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::ShopifyClient

  description 'Suggest upsell and cross-sell products based on the current product selection.'
  param :product_id, type: 'string', desc: 'Shopify product ID to base suggestions on', required: true
  param :context, type: 'string', desc: 'What the customer is looking for', required: false

  def active?
    shopify_active?
  end

  def perform(_tool_context, product_id:, context: nil)
    log_tool_usage('shopify_suggest_products', { product_id: product_id })
    product = fetch_product(product_id)
    return "Product ID '#{product_id}' not found" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  private

  def fetch_product(id)
    result = shopify_get("products/#{id}.json")
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

    base_price = product['variants']&.first&.dig('price').to_f
    fetch_by_type(product['product_type'])
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .select { |p| p['variants']&.first&.dig('price').to_f > base_price }
      .first(3)
      .map { |p| format_entry(p, 'Premium option') }
  end

  def find_same_type_products(product)
    return [] if product['product_type'].blank?

    fetch_by_type(product['product_type'])
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .first(3)
      .map { |p| format_entry(p, 'Same type') }
  end

  def fetch_by_type(product_type)
    result = shopify_get('products.json', { product_type: product_type, limit: 10 })
    result&.dig('products') || []
  end

  def format_entry(product, reason)
    stock = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
    price = product['variants']&.first&.dig('price').to_f
    { name: product['title'], price: price, stock: stock, reason: reason }
  end

  def format_suggestions(product, suggestions, context)
    price = product['variants']&.first&.dig('price').to_f
    lines = ["Product: #{product['title']} (ID: #{product['id']}) — #{format_currency(price, 'VND')}\n"]
    lines << "Customer context: #{context}\n" if context.present?
    append_section(lines, '⬆️ Upsell options:', suggestions[:upsell])
    append_section(lines, '📦 More from same type:', suggestions[:same_type])
    lines << 'No suggestions available.' if suggestions.values.all?(&:blank?)
    lines.join("\n")
  end

  def append_section(lines, title, items)
    return if items.blank?

    lines << title
    items.each { |s| lines << "  • #{s[:name]} — #{format_currency(s[:price], 'VND')} | Stock: #{s[:stock]} (#{s[:reason]})" }
  end
end
