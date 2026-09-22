# Copilot tool: Agent creates a draft order via AI with Sapo products.
class Captain::Tools::Copilot::Sapo::CreateOrderService < Captain::Tools::Copilot::BaseCreateOrderService
  include Captain::Tools::Sapo::Client

  def self.name
    'sapo_create_order'
  end

  description 'Create a draft order with Sapo products. Validates stock and creates the order for agent review.'

  private

  def platform_name
    'sapo'
  end

  def platform_active?
    sapo_active?
  end

  def resolve_product(id)
    result = sapo_get("products/#{id}.json")
    result&.dig('product')
  end

  def extract_price(product)
    product['variants']&.first&.dig('price').to_f
  end

  def extract_stock(product)
    total = product['variants']&.sum { |v| v['inventory_quantity'].to_i } || 0
    { total: total, status: stock_status(total) }
  end

  def extract_product_name(product)
    product['name']
  end

  def extract_thumbnail(product)
    product.dig('images', 0, 'src')
  end

  def format_currency(amount)
    format_sapo_currency(amount)
  end
end
