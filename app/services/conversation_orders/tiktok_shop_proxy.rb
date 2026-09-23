# Proxy for TikTok Shop Order API.
# TikTok Shop does NOT support creating orders via API — orders come from the marketplace.
# This proxy only supports fetching/syncing existing orders.
class ConversationOrders::TiktokShopProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::TiktokShop::Client

  def create_order(_payload)
    # TikTok Shop orders are created by buyers on the marketplace.
    # We cannot push new orders via API.
    nil
  end

  def fetch_order(order_id)
    result = tiktok_shop_get('/order/202309/orders', { ids: [order_id] })
    result&.dig('data', 'orders')&.first
  end

  def fetch_products(page = 1)
    page_size = 50
    result = tiktok_shop_post('/product/202309/products/search', { page_size: page_size, page_number: page })
    
    products = result&.dig('data', 'products')
    return [[], false] if products.blank?

    products_data = products.map do |item|
      {
        external_id: item['id'].to_s,
        name: item['title'],
        description: item['description'],
        price: item.dig('skus', 0, 'price', 'original_price') || 0,
        currency: item.dig('skus', 0, 'price', 'currency') || 'VND',
        sku: item.dig('skus', 0, 'seller_sku'),
        barcode: nil,
        status: item['status'] == 'ACTIVATE' ? 'active' : 'archived',
        variants: item['skus']&.map do |sku|
          {
            external_id: sku['id'].to_s,
            name: sku['sales_attributes']&.map { |a| a['value_name'] }&.join(' - ') || item['title'],
            price: sku.dig('price', 'original_price'),
            sku: sku['seller_sku'],
            barcode: nil,
            inventory_quantity: sku['inventory']&.sum { |i| i['quantity'] } || 0,
            compare_at_price: nil
          }
        end || []
      }
    end

    total_count = result.dig('data', 'total_count').to_i
    has_more = (page * page_size) < total_count

    [products_data, has_more]
  end

  def map_status(raw_status)
    # TikTok Shop: UNPAID, ON_HOLD, AWAITING_SHIPMENT, AWAITING_COLLECTION,
    #              IN_TRANSIT, DELIVERED, COMPLETED, CANCELLED
    case raw_status.to_s.upcase
    when 'UNPAID', 'ON_HOLD' then :confirmed
    when 'AWAITING_SHIPMENT', 'AWAITING_COLLECTION' then :processing
    when 'IN_TRANSIT' then :shipped
    when 'DELIVERED', 'COMPLETED' then :delivered
    when 'CANCELLED' then :cancelled
    end
  end

  def extract_order_id(result)
    result&.dig('data', 'orders')&.first&.dig('id')&.to_s
  end

  def extract_error(result)
    result&.dig('message') || super
  end

  def extract_raw_status(result)
    result['status']
  end

  def extract_total(result)
    result.dig('payment', 'total_amount')
  end
end
