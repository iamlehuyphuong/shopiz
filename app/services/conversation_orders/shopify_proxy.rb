# Proxy for Shopify Order API.
# Uses the ShopifyAPI gem (REST Admin client).
class ConversationOrders::ShopifyProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::ShopifyClient

  def create_order(payload)
    shopify_post('orders.json', { order: payload })
  end

  def update_order(order_id, payload)
    shopify_put("orders/#{order_id}.json", { order: payload })
  end

  def fetch_order(order_id)
    result = shopify_get("orders/#{order_id}.json")
    result&.dig('order')
  end

  def fetch_products(page = 1)
    @next_page_info = nil if page == 1

    response = shopify_client.get(path: 'products.json', query: products_query)
    products = response.body['products'] || []

    products_data = products.map { |item| normalize_product(item) }
    has_more = extract_next_page_info(response)

    [products_data, has_more]
  rescue StandardError => e
    Rails.logger.error("ShopifyProxy fetch_products error: #{e.message}")
    [[], false]
  end

  def map_status(raw_status)
    # Shopify: financial_status
    case raw_status.to_s.downcase
    when 'pending', 'authorized' then :confirmed
    when 'partially_paid' then :processing
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

  def products_query
    query = { limit: 50 }
    query[:page_info] = @next_page_info if @next_page_info.present?
    query
  end

  def normalize_product(item)
    {
      external_id: item['id'].to_s,
      name: item['title'],
      description: item['body_html'],
      price: item.dig('variants', 0, 'price') || 0,
      currency: 'VND',
      sku: item.dig('variants', 0, 'sku'),
      barcode: item.dig('variants', 0, 'barcode'),
      status: item['status'],
      variants: normalize_variants(item['variants'])
    }
  end

  def normalize_variants(variants)
    return [] if variants.blank?

    variants.map do |v|
      {
        external_id: v['id'].to_s,
        name: v['title'],
        price: v['price'],
        sku: v['sku'],
        barcode: v['barcode'],
        inventory_quantity: v['inventory_quantity'] || 0,
        compare_at_price: v['compare_at_price']
      }
    end
  end

  def extract_next_page_info(response)
    link_header = response.headers&.to_h&.transform_keys(&:downcase)&.dig('link')
    return false unless link_header&.match?(/page_info=([^>]+)>; rel="next"/)

    @next_page_info = link_header.match(/page_info=([^>]+)>; rel="next"/)[1]
    true
  end
end
