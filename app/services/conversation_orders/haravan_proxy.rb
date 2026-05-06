# Proxy for Haravan Order API.
# Haravan REST API: POST /com/orders.json, GET /com/orders/{id}.json
class ConversationOrders::HaravanProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::HaravanClient

  def create_order(payload)
    haravan_post('orders.json', { order: payload })
  end

  def fetch_order(order_id)
    result = haravan_get("orders/#{order_id}.json")
    result&.dig('order')
  end

  def fetch_products(page = 1)
    limit = 50
    result = haravan_get("products.json?limit=#{limit}&page=#{page}")
    
    products = result&.dig('products')
    return [[], false] if products.blank?

    products_data = products.map do |item|
      {
        external_id: item['id'].to_s,
        name: item['title'],
        description: item['body_html'],
        price: item.dig('variants', 0, 'price') || 0,
        currency: 'VND',
        sku: item.dig('variants', 0, 'sku'),
        barcode: item.dig('variants', 0, 'barcode'),
        status: item['published_at'].present? ? 'active' : 'draft',
        variants: item['variants']&.map do |v|
          {
            external_id: v['id'].to_s,
            name: v['title'],
            price: v['price'],
            sku: v['sku'],
            barcode: v['barcode'],
            inventory_quantity: v['inventory_quantity'] || 0,
            compare_at_price: v['compare_at_price']
          }
        end || []
      }
    end

    has_more = products.length == limit

    [products_data, has_more]
  end

  def map_status(raw_status)
    # Haravan uses Shopify-like statuses
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
end
