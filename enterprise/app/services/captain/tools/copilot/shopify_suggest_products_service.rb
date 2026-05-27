# Copilot tool: Suggest products from Shopify.
class Captain::Tools::Copilot::ShopifySuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::ShopifyClient

  def self.name
    'shopify_suggest_products'
  end

  description 'Suggest upsell and cross-sell products based on a Shopify product.'
  param :product_id, type: :string, desc: 'Shopify product ID', required: true
  param :context, type: :string, desc: 'Customer context', required: false

  def execute(product_id:, context: nil)
    return 'Shopify integration is not connected' unless shopify_active?

    product = fetch_product(product_id)
    return "Product '#{product_id}' not found" if product.nil?

    suggestions = gather_suggestions(product)
    format_suggestions(product, suggestions, context)
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def fetch_product(id)
    result = shopify_get("products/#{id}.json")
    result&.dig('product')
  end

  def gather_suggestions(product)
    { same_type: find_same_type(product) }
  end

  def find_same_type(product)
    return [] if product['product_type'].blank?

    result = shopify_get('products.json', { product_type: product['product_type'], limit: 10 })
    (result&.dig('products') || [])
      .reject { |p| p['id'].to_s == product['id'].to_s }
      .first(5)
      .map { |p| format_entry(p) }
  end

  def format_entry(product)
    stock = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
    price = product['variants']&.first&.dig('price').to_f
    { name: product['title'], price: price, stock: stock }
  end

  def format_suggestions(product, suggestions, context)
    price = product['variants']&.first&.dig('price').to_f
    lines = ["Base: #{product['title']} (ID: #{product['id']}) — #{format_currency(price, 'VND')}"]
    lines << "Context: #{context}" if context.present?
    if suggestions[:same_type].present?
      lines << "\nRelated products:"
      suggestions[:same_type].each { |s| lines << " • #{s[:name]} — #{format_currency(s[:price], 'VND')} | Stock: #{s[:stock]}" }
    else
      lines << 'No suggestions available.'
    end
    lines.join("\n")
  end
end
