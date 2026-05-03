# Copilot tool: Check inventory/stock for Sapo products.
class Captain::Tools::Copilot::SapoCheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SapoClient

  def self.name
    'sapo_check_inventory'
  end

  description 'Check current stock levels for one or more Sapo products by ID.'
  param :product_ids, type: :string, desc: 'Comma-separated product IDs (e.g. "123,456")', required: true

  def execute(product_ids:)
    return 'Sapo integration is not connected' unless sapo_active?

    ids = product_ids.split(',').map(&:strip).reject(&:blank?)
    return 'Please provide at least one product ID' if ids.blank?

    results = ids.map { |id| check_product(id) }
    format_results(results)
  end

  def active?
    @user.present? && sapo_active?
  end

  private

  def check_product(id)
    result = sapo_get("products/#{id}.json")
    product = result&.dig('product')
    return { id: id, error: 'Not found' } if product.nil?

    build_stock_info(product, id)
  end

  def build_stock_info(product, id)
    variants = product['variants'] || []
    total = variants.sum { |v| v['inventory_quantity'].to_i }
    {
      id: id, name: product['name'], total: total,
      variants: variants.map { |v| { sku: v['sku'], stock: v['inventory_quantity'].to_i, title: v['title'] } },
      status: stock_status(total), icon: stock_icon(total)
    }
  end

  def stock_status(total)
    return 'In Stock' if total > 10
    return 'Low Stock' if total.positive?

    'Out of Stock'
  end

  def stock_icon(total)
    return '🟢' if total > 10
    return '🟡' if total.positive?

    '🔴'
  end

  def format_results(results)
    lines = ['📊 Sapo Inventory Check:', '']
    results.each { |r| lines.concat(format_single(r)) }
    lines.join("\n")
  end

  def format_single(result)
    return ["❌ ID #{result[:id]}: #{result[:error]}", ''] if result[:error]

    lines = ["#{result[:icon]} #{result[:name]} (ID: #{result[:id]}) — #{result[:status]}", "   Total: #{result[:total]}"]
    result[:variants]&.each { |v| lines << "   - #{v[:title]}: #{v[:stock]} (SKU: #{v[:sku] || 'N/A'})" }
    lines << ''
    lines
  end
end
