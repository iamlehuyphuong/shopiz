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

  def fetch_orders(params = {})
    woocommerce_get('orders', params)
  end

  def update_order(order_id, payload)
    woocommerce_put("orders/#{order_id}", payload)
  end

  def delete_order(order_id)
    woocommerce_delete("orders/#{order_id}")
  end

  def fetch_customers(params = {})
    woocommerce_get('customers', params)
  end

  def fetch_customer(id)
    woocommerce_get("customers/#{id}")
  end

  def create_customer(payload)
    woocommerce_post('customers', payload)
  end

  def update_customer(id, payload)
    woocommerce_put("customers/#{id}", payload)
  end

  def fetch_products(page = 1)
    limit = 50
    Rails.logger.info("WoocommerceProxy: Making GET request to products with page=#{page}")
    result = woocommerce_get('products', { per_page: limit, page: page, status: 'publish' })

    if result.blank? || !result.is_a?(Array)
      Rails.logger.warn('WoocommerceProxy: fetch_products returning empty. ' \
                        "result.blank?: #{result.blank?}, is_a?(Array): #{result.is_a?(Array)}")
      return [[], false]
    end

    Rails.logger.info("WoocommerceProxy: Successfully fetched #{result.length} products on page #{page}")

    products_data = result.map { |item| map_product(item) }

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

  private

  def map_product(item)
    {
      external_id: item['id'].to_s,
      name: item['name'],
      description: item['description'],
      price: item['price'].to_f,
      currency: 'VND',
      sku: item['sku'],
      barcode: nil,
      status: item['status'] == 'publish' ? 'active' : 'draft',
      variants: fetch_variations(item)
    }
  end

  def fetch_variations(item)
    return [] unless item['type'] == 'variable'

    Rails.logger.info("WoocommerceProxy: Fetching variations for product #{item['id']}")
    variations = woocommerce_get("products/#{item['id']}/variations", { per_page: 100 })
    return [] unless variations.is_a?(Array)

    variations.map { |variant| map_variation(item, variant) }
  rescue StandardError => e
    Rails.logger.error("WoocommerceProxy: Failed to fetch variations for product #{item['id']}: #{e.message}")
    []
  end

  def map_variation(item, variant)
    name = variant['name'].presence || variant['attributes']&.pluck('option')&.join(' - ') || item['name']

    {
      external_id: variant['id'].to_s,
      name: name,
      price: variant['price'].to_f,
      sku: variant['sku'],
      barcode: nil,
      inventory_quantity: variant['stock_quantity'] || 0,
      compare_at_price: variant['regular_price'].to_f
    }
  end
end
