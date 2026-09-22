# Copilot tool: Check inventory/stock for Sapo products.
class Captain::Tools::Copilot::Sapo::CheckInventoryService < Captain::Tools::Copilot::BaseCheckInventoryService
  include Captain::Tools::Sapo::Client

  def self.name
    'sapo_check_inventory'
  end

  description 'Check current stock levels for one or more Sapo products by ID.'

  private

  def platform_name
    'sapo'
  end

  def platform_active?
    sapo_active?
  end

  def fetch_product(id)
    result = sapo_get("products/#{id}.json")
    result&.dig('product')
  end

  def extract_product_name(product)
    product['name']
  end

  def compute_stock_info(product, _identifier)
    variants = product['variants'] || []
    total = variants.sum { |v| v['inventory_quantity'].to_i }
    status = stock_status(total, threshold: 10)

    details = variants.map do |v|
      { label: "#{v['title']} (SKU: #{v['sku'] || 'N/A'})", quantity: v['inventory_quantity'].to_i }
    end

    { total: total, status: status, details: details }
  end
end
