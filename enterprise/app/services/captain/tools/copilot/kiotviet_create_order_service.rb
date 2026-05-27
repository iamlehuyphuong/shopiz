# Copilot tool: Agent creates a draft order via AI with KiotViet products.
# Validates stock, creates ConversationOrder in Flowify for review.
class Captain::Tools::Copilot::KiotvietCreateOrderService < Captain::Tools::Copilot::BaseCreateOrderService
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_create_order'
  end

  description 'Create a draft order with KiotViet products. Validates stock availability ' \
              'and creates the order in Flowify for agent review before pushing to KiotViet.'

  private

  def platform_name
    'kiotviet'
  end

  def platform_active?
    kiotviet_active?
  end

  def product_identifier_key
    'code'
  end

  def resolve_product(code)
    result = kiotviet_get('products/code', { code: code })
    result.is_a?(Hash) && result['id'] ? result : nil
  end

  def extract_price(product)
    product['basePrice'].to_f
  end

  def extract_stock(product)
    total = product['inventories']&.sum { |inv| inv['onHand'].to_f }.to_i || 0
    { total: total, status: stock_status(total) }
  end

  def extract_product_name(product)
    product['fullName'] || product['name']
  end

  def extract_thumbnail(product)
    product.dig('images', 0)
  end

  def format_currency(amount)
    format_vnd(amount)
  end
end
