# Base class for platform-specific "Check Inventory"copilot tools.
# Subclasses only need to implement:
#   - platform_name       (e.g. 'kiotviet')
#   - platform_active?    (check integration)
#   - fetch_product(identifier) -> Hash or nil
#   - extract_product_name(product) -> String
#   - compute_stock_info(product, identifier) -> Hash { total:, status:, details: [] }
class Captain::Tools::Copilot::BaseCheckInventoryService < Captain::Tools::BaseTool
  param :product_identifiers, type: :string, desc: 'Comma-separated product codes or IDs (e.g. "SP001,SP002")', required: true

  def execute(product_identifiers:)
    return "#{platform_label} integration is not connected" unless platform_active?

    ids = product_identifiers.split(',').map(&:strip).reject(&:blank?)
    return 'Please provide at least one product identifier' if ids.empty?

    results = ids.map { |id| check_product_stock(id) }
    format_results(results)
  end

  def active?
    @user.present? && platform_active?
  end

  private

  # --- Subclass hooks (must override) ---

  def platform_name
    raise NotImplementedError
  end

  def platform_label
    platform_name.titleize
  end

  def platform_active?
    raise NotImplementedError
  end

  def fetch_product(_identifier)
    raise NotImplementedError
  end

  def extract_product_name(_product)
    raise NotImplementedError
  end

  def compute_stock_info(_product, _identifier)
    raise NotImplementedError
  end

  # --- Shared logic ---

  def check_product_stock(identifier)
    product = fetch_product(identifier)
    return { identifier: identifier, found: false } if product.nil?

    info = compute_stock_info(product, identifier)
    info.merge(identifier: identifier, found: true, name: extract_product_name(product))
  end

  def stock_status(total, threshold: 5)
    return 'In Stock' if total > threshold
    return 'Low Stock' if total.positive?

    'Out of Stock'
  end

  def stock_emoji(status)
    { 'In Stock' => '', 'Low Stock' => '' }[status] || ''
  end

  def format_results(results)
    lines = ["#{platform_label} Inventory Check:\n"]
    results.each { |r| lines.concat(format_single_result(r)) }
    lines.join("\n")
  end

  def format_single_result(result)
    return ["#{result[:identifier]} — Product not found", ''] unless result[:found]

    status = result[:status]
    lines = ["#{stock_emoji(status)} #{result[:name]} (#{result[:identifier]}) — Total: #{result[:total]} (#{status})"]
    append_details(lines, result[:details]) if result[:details].present?
    lines << ''
    lines
  end

  def append_details(lines, details)
    details.each { |d| lines << "  └ #{d[:label]}: #{d[:quantity]}" }
  end
end
