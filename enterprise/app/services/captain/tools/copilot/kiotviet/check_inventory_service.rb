# Copilot tool: Check inventory levels for KiotViet products.
class Captain::Tools::Copilot::Kiotviet::CheckInventoryService < Captain::Tools::Copilot::BaseCheckInventoryService
  include Captain::Tools::Kiotviet::Client

  def self.name
    'kiotviet_check_inventory'
  end

  description 'Check current inventory (stock) levels for one or more KiotViet products across all branches.'

  private

  def platform_name
    'kiotviet'
  end

  def platform_active?
    kiotviet_active?
  end

  def fetch_product(code)
    result = kiotviet_get('products/code', { code: code })
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def extract_product_name(product)
    product['fullName'] || product['name']
  end

  def compute_stock_info(product, _identifier)
    inventories = product['inventories'] || []
    total = inventories.sum { |inv| inv['onHand'].to_i }
    status = stock_status(total)

    details = inventories.map do |inv|
      { label: inv['branchName'] || "Branch ##{inv['branchId']}", quantity: inv['onHand'].to_i }
    end

    { total: total, status: status, details: details }
  end
end
