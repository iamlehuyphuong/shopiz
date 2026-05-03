# Copilot tool: Check inventory levels for KiotViet products.
class Captain::Tools::Copilot::KiotvietCheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_check_inventory'
  end

  description 'Check current inventory (stock) levels for one or more KiotViet products across all branches.'
  param :product_codes, type: :string, desc: 'Comma-separated product codes to check (e.g. "SP001,SP002,SP003")', required: true

  def execute(product_codes:)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    codes = product_codes.split(',').map(&:strip).reject(&:blank?)
    return 'Please provide at least one product code' if codes.empty?

    results = codes.map { |code| check_product_stock(code) }
    format_results(results)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def check_product_stock(code)
    product = lookup_product(code)
    return { code: code, found: false } if product.nil?

    build_stock_result(code, product)
  end

  def lookup_product(code)
    result = kiotviet_get('products/code', { code: code })
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def build_stock_result(code, product)
    branch_stock = extract_branch_stock(product['inventories'])
    total = branch_stock.sum { |b| b[:on_hand] }

    {
      code: code, found: true,
      name: product['fullName'] || product['name'],
      total_stock: total,
      status: stock_status(total),
      branches: branch_stock
    }
  end

  def extract_branch_stock(inventories)
    (inventories || []).map do |inv|
      { branch: inv['branchName'] || "Branch ##{inv['branchId']}", on_hand: inv['onHand'].to_i }
    end
  end

  def stock_status(total)
    return 'In Stock' if total > 5
    return 'Low Stock' if total.positive?

    'Out of Stock'
  end

  def format_results(results)
    lines = ["📊 Inventory Check Results:\n"]
    results.each { |r| lines.concat(format_single_result(r)) }
    lines.join("\n")
  end

  def format_single_result(result)
    return ["❓ #{result[:code]} — Product not found", ''] unless result[:found]

    lines = ["#{stock_emoji(result[:status])} #{result[:name]} (#{result[:code]}) — Total: #{result[:total_stock]} (#{result[:status]})"]
    append_branch_details(lines, result[:branches])
    lines << ''
    lines
  end

  def stock_emoji(status)
    { 'In Stock' => '🟢', 'Low Stock' => '🟡' }[status] || '🔴'
  end

  def append_branch_details(lines, branches)
    return unless branches.present? && branches.size > 1

    branches.each { |b| lines << "   └ #{b[:branch]}: #{b[:on_hand]}" }
  end
end
