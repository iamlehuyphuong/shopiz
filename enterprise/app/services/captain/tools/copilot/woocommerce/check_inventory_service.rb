# Copilot tool: Check inventory for WooCommerce products.
# WooCommerce uses stock_quantity/stock_status on the product level (simple products).
class Captain::Tools::Copilot::Woocommerce::CheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Woocommerce::Client

  def self.name
    'woocommerce_check_inventory'
  end

  description 'Check current stock levels for one or more WooCommerce products by ID.'
  param :product_ids, type: :string, desc: 'Comma-separated product IDs', required: true

  def execute(product_ids:)
    return 'WooCommerce integration is not connected' unless woocommerce_active?

    ids = product_ids.split(',').map(&:strip).reject(&:blank?)
    return 'Please provide at least one product ID' if ids.blank?

    results = ids.map { |id| check_product(id) }
    format_results(results)
  end

  def active?
    @user.present? && woocommerce_active?
  end

  private

  def check_product(id)
    result = woocommerce_get("products/#{id}")
    return { id: id, error: 'Not found' } unless result.is_a?(Hash) && result['id']

    build_info(result, id)
  end

  def build_info(product, id)
    stock = product['stock_quantity'].to_i
    {
      id: id, name: product['name'], total: stock,
      stock_status: product['stock_status'],
      manage_stock: product['manage_stock'],
      status: stock_status(stock, product['stock_status']),
      icon: stock_icon(stock, product['stock_status'])
    }
  end

  def stock_status(quantity, woo_status)
    return woo_status&.humanize || 'Unknown' unless quantity.positive?
    return 'In Stock' if quantity > 10
    return 'Low Stock' if quantity.positive?

    'Out of Stock'
  end

  def stock_icon(quantity, woo_status)
    return '🟢' if woo_status == 'instock' && quantity > 10
    return '🟡' if woo_status == 'instock'
    return '🟠' if woo_status == 'onbackorder'

    '🔴'
  end

  def format_results(results)
    lines = ['📊 WooCommerce Inventory Check:', '']
    results.each { |r| lines.concat(format_single(r)) }
    lines.join("\n")
  end

  def format_single(result)
    return ["❌ ID #{result[:id]}: #{result[:error]}", ''] if result[:error]

    [
      "#{result[:icon]} #{result[:name]} (ID: #{result[:id]}) — #{result[:status]}",
      "   Quantity: #{result[:total]} | WooCommerce Status: #{result[:stock_status]}",
      ''
    ]
  end
end
