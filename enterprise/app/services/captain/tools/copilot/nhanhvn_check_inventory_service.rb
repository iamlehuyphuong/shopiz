# Copilot tool: Check inventory/stock for Nhanh.vn products by code.
class Captain::Tools::Copilot::NhanhvnCheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::NhanhvnClient

  def self.name
    'nhanhvn_check_inventory'
  end

  description 'Check current inventory/stock levels for one or more Nhanh.vn products by code. ' \
              'Returns available stock with status indicators.'
  param :product_codes, type: :string, desc: 'Comma-separated product codes (e.g. "SP001,SP002")', required: true

  def execute(product_codes:)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    codes = product_codes.split(',').map(&:strip).reject(&:blank?)
    return 'Please provide at least one product code' if codes.blank?

    results = codes.map { |code| check_product(code) }
    format_inventory_results(results)
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def check_product(code)
    result = nhanhvn_post('/api/product/search', { code: code, icpp: 1 })
    products_hash = result&.dig('data', 'products')

    return { code: code, error: 'Not found' } unless products_hash.is_a?(Hash) && products_hash.values.any?

    product = products_hash.values.first
    build_stock_info(product, code)
  end

  def build_stock_info(product, code)
    inventory = product['inventory'] || {}
    available = inventory['available'].to_i
    shipping = inventory['shipping'].to_i
    holding = inventory['holding'].to_i
    actual = inventory['actualStock'].to_i

    {
      code: code,
      name: product['name'],
      available: available,
      shipping: shipping,
      holding: holding,
      actual: actual,
      status: stock_status(available),
      icon: stock_icon(available)
    }
  end

  def stock_status(available)
    if available > 10
      'In Stock'
    elsif available.positive?
      'Low Stock'
    else
      'Out of Stock'
    end
  end

  def stock_icon(available)
    return '' if available > 10
    return '' if available.positive?

    ''
  end

  def format_inventory_results(results)
    lines = ['📊 Inventory Check Results:', '']
    results.each { |r| lines.concat(format_single_result(r)) }
    lines.join("\n")
  end

  def format_single_result(result)
    if result[:error]
      ["#{result[:code]}: #{result[:error]}", '']
    else
      [
        "#{result[:icon]} #{result[:name]} (#{result[:code]}) — #{result[:status]}",
        "  Available: #{result[:available]} | Shipping: #{result[:shipping]} | Holding: #{result[:holding]} | Actual: #{result[:actual]}",
        ''
      ]
    end
  end
end
