# Copilot tool: Suggest upsell/cross-sell products from Haravan.
class Captain::Tools::Copilot::HaravanSuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def self.name
    'haravan_suggest_products'
  end

  description 'Suggest upsell and cross-sell products based on a Haravan product.'
  param :product_id, type: :string, desc: 'Haravan product ID', required: true
  param :context, type: :string, desc: 'Customer context from conversation', required: false

  def execute(product_id:, context: nil)
    return 'Haravan integration is not connected' unless haravan_active?

    product = fetch_product(product_id)
    return "Product '#{product_id}' not found on Haravan" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  def active?
    @user.present? && haravan_active?
  end

  private

  def fetch_product(id)
    result = haravan_get("products/#{id}.json")
    result&.dig('product')
  end

  def gather_suggestions(product)
    {
      upsell: find_upsells(product),
      same_type: find_same_type(product)
    }
  end

  def find_upsells(product)
    return [] if product['product_type'].blank?

    base_price = product['variants']&.first&.dig('price').to_f
    fetch_by_type(product['product_type'])
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .select { |p| p['variants']&.first&.dig('price').to_f > base_price }
      .first(3)
      .map { |p| format_entry(p, 'Premium option') }
  end

  def find_same_type(product)
    return [] if product['product_type'].blank?

    fetch_by_type(product['product_type'])
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .first(3)
      .map { |p| format_entry(p, 'Same type') }
  end

  def fetch_by_type(product_type)
    result = haravan_get('products.json', { product_type: product_type, limit: 10 })
    result&.dig('products') || []
  end

  def format_entry(product, reason)
    stock = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
    price = product['variants']&.first&.dig('price').to_f
    { name: product['title'], price: price, stock: stock, reason: reason }
  end

  def format_suggestions(product, suggestions, context)
    price = product['variants']&.first&.dig('price').to_f
    lines = ["📦 Base: #{product['title']} (ID: #{product['id']}) — #{format_haravan_currency(price)}"]
    lines << "🎯 Context: #{context}" if context.present?
    append_section(lines, '⬆️ Upsell:', suggestions[:upsell])
    append_section(lines, '🔄 Same type:', suggestions[:same_type])
    lines << 'No suggestions available.' if suggestions.values.all?(&:blank?)
    lines.join("\n")
  end

  def append_section(lines, title, items)
    return if items.blank?

    lines << "\n#{title}"
    items.each { |s| lines << "  • #{s[:name]} — #{format_haravan_currency(s[:price])} | Stock: #{s[:stock]} (#{s[:reason]})" }
  end
end
