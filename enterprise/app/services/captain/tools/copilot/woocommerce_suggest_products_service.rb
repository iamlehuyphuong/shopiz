# Copilot tool: Suggest products from WooCommerce.
# Leverages native upsell_ids and cross_sell_ids fields.
class Captain::Tools::Copilot::WoocommerceSuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient

  def self.name
    'woocommerce_suggest_products'
  end

  description 'Suggest upsell and cross-sell products based on a WooCommerce product.'
  param :product_id, type: :string, desc: 'WooCommerce product ID', required: true
  param :context, type: :string, desc: 'Customer context', required: false

  def execute(product_id:, context: nil)
    return 'WooCommerce integration is not connected' unless woocommerce_active?

    product = fetch_product(product_id)
    return "Product '#{product_id}' not found" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  def active?
    @user.present? && woocommerce_active?
  end

  private

  def fetch_product(id)
    result = woocommerce_get("products/#{id}")
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def gather_suggestions(product)
    {
      upsell: fetch_related(product['upsell_ids']),
      cross_sell: fetch_related(product['cross_sell_ids']),
      same_category: find_category_products(product)
    }
  end

  def fetch_related(ids)
    return [] if ids.blank?

    ids.first(3).filter_map { |id| fetch_product(id) }.map { |p| format_entry(p, 'Recommended') }
  end

  def find_category_products(product)
    cat = product['categories']&.first
    return [] if cat.nil?

    products = woocommerce_get('products', { category: cat['id'], per_page: 5, status: 'publish' })
    return [] unless products.is_a?(Array)

    products.reject { |p| p['id'].to_s == product['id'].to_s }.first(3).map { |p| format_entry(p, 'Same category') }
  end

  def format_entry(product, reason)
    { name: product['name'], price: product['price'].to_f, stock: product['stock_quantity'].to_i, reason: reason }
  end

  def format_suggestions(product, suggestions, context)
    lines = ["📦 Base: #{product['name']} (ID: #{product['id']}) — #{format_woo_currency(product['price'])}"]
    lines << "🎯 Context: #{context}" if context.present?
    append_section(lines, '⬆️ Upsell:', suggestions[:upsell])
    append_section(lines, '🔗 Cross-sell:', suggestions[:cross_sell])
    append_section(lines, '📦 Same category:', suggestions[:same_category])
    lines << 'No suggestions available.' if suggestions.values.all?(&:blank?)
    lines.join("\n")
  end

  def append_section(lines, title, items)
    return if items.blank?

    lines << "\n#{title}"
    items.each { |s| lines << "  • #{s[:name]} — #{format_woo_currency(s[:price])} | Stock: #{s[:stock]} (#{s[:reason]})" }
  end
end
