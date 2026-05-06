# Proxy for WooCommerce Order API.
# WooCommerce REST API v3: POST /orders, GET /orders/{id}
class ConversationOrders::WoocommerceProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::WoocommerceClient

  def create_order(payload)
    woocommerce_post('orders', payload)
  end

  def fetch_order(order_id)
    woocommerce_get("orders/#{order_id}")
  end

  def fetch_products(page = 1)
    limit = 50
    Rails.logger.info("WoocommerceProxy: Making GET request to products with page=#{page}")
    result = woocommerce_get('products', { per_page: limit, page: page, status: 'publish' })
    
    if result.blank? || !result.is_a?(Array)
      Rails.logger.warn("WoocommerceProxy: fetch_products returning empty. result.blank?: #{result.blank?}, is_a?(Array): #{result.is_a?(Array)}, result: #{result.inspect}")
      return [[], false]
    end

    Rails.logger.info("WoocommerceProxy: Successfully fetched #{result.length} products on page #{page}")

    products_data = result.map do |item|
      {
        external_id: item['id'].to_s,
        name: item['name'],
        description: item['description'],
        price: item['price'].to_f,
        currency: 'VND',
        sku: item['sku'],
        barcode: nil,
        status: item['status'] == 'publish' ? 'active' : 'draft',
        variants: []
      }
    end

    has_more = result.length == limit
    [products_data, has_more]
  rescue StandardError => e
    Rails.logger.error("WoocommerceProxy fetch_products error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    [[], false]
  end

  def map_status(raw_status)
    # WooCommerce: pending, processing, on-hold, completed, cancelled, refunded, failed
    case raw_status.to_s.downcase
    when 'pending', 'on-hold' then :confirmed
    when 'processing' then :processing
    when 'completed' then :delivered
    when 'cancelled', 'refunded', 'failed' then :cancelled
    end
  end

  def extract_order_id(result)
    result&.dig('id')&.to_s
  end

  def extract_error(result)
    result&.dig('message') || super
  end
end
