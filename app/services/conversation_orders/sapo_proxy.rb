# Proxy for Sapo Order API.
# Sapo REST Admin API: POST /admin/orders.json, GET /admin/orders/{id}.json
class ConversationOrders::SapoProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::SapoClient

  def create_order(payload)
    sapo_post('orders.json', { order: payload })
  end

  def fetch_order(order_id)
    result = sapo_get("orders/#{order_id}.json")
    result&.dig('order')
  end

  def fetch_products(page = 1)
    limit = 50
    result = sapo_get('products.json', { limit: limit, page: page })

    products = result&.dig('products')
    return [[], false] if products.blank?

    products_data = products.map { |item| normalize_product(item) }
    [products_data, products.length == limit]
  rescue StandardError => e
    Rails.logger.error("SapoProxy fetch_products error: #{e.message}")
    [[], false]
  end

  def map_status(raw_status)
    # Sapo: financial_status / fulfillment_status
    case raw_status.to_s.downcase
    when 'pending' then :confirmed
    when 'authorized', 'partially_paid' then :processing
    when 'paid' then :delivered
    when 'voided', 'refunded' then :cancelled
    end
  end

  def extract_order_id(result)
    result&.dig('order', 'id')&.to_s
  end

  def extract_error(result)
    result&.dig('errors')&.to_s || super
  end

  private

  def normalize_product(item)
    {
      external_id: item['id'].to_s,
      name: item['name'] || item['title'],
      description: item['body_html'] || item['description'],
      price: item.dig('variants', 0, 'price') || 0,
      currency: 'VND',
      sku: item.dig('variants', 0, 'sku'),
      barcode: item.dig('variants', 0, 'barcode'),
      status: item['status'] == 'active' ? 'active' : 'draft',
      variants: normalize_variants(item['variants'])
    }
  end

  def normalize_variants(variants)
    return [] if variants.blank?

    variants.map do |v|
      {
        external_id: v['id'].to_s,
        name: v['name'] || v['title'],
        price: v['price'],
        sku: v['sku'],
        barcode: v['barcode'],
        inventory_quantity: v['inventory_quantity'] || 0,
        compare_at_price: v['compare_at_price']
      }
    end
  end
end
