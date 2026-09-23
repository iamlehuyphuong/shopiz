# Proxy for Nhanh.vn Order API.
# Nhanh.vn uses POST-only endpoints with form-encoded data.
class ConversationOrders::NhanhvnProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Nhanhvn::Client

  def create_order(payload)
    nhanhvn_post('/api/order/add', payload)
  end

  def update_order(order_id, payload)
    nhanhvn_post('/api/order/update', payload.merge(id: order_id))
  end

  def fetch_order(order_id)
    result = nhanhvn_post('/api/order/detail', { id: order_id })
    result&.dig('data')
  end

  def fetch_products(page = 1)
    limit = 50
    result = nhanhvn_post('/api/product/search', { icpp: limit, page: page })

    products_hash = result&.dig('data', 'products')
    return [[], false] unless products_hash.is_a?(Hash)

    products = products_hash.values
    return [[], false] if products.blank?

    products_data = products.map { |item| normalize_product(item) }
    has_more = result.dig('data', 'page').to_i < result.dig('data', 'totalPages').to_i

    [products_data, has_more]
  rescue StandardError => e
    Rails.logger.error("NhanhvnProxy fetch_products error: #{e.message}")
    [[], false]
  end

  def map_status(raw_status)
    # Nhanh.vn: New, Confirmed, Packing, Packed, Shipping, Success, Canceled, Returned
    case raw_status.to_s.downcase
    when 'new' then :draft
    when 'confirmed', 'packing', 'packed' then :confirmed
    when 'shipping' then :shipped
    when 'success' then :delivered
    when 'canceled', 'returned' then :cancelled
    end
  end

  def extract_order_id(result)
    result&.dig('data', 'orderId')&.to_s || result&.dig('data', 'id')&.to_s
  end

  def extract_error(result)
    result&.dig('messages')&.values&.first || super
  end

  private

  def normalize_product(item)
    {
      external_id: item['idNhanh'].to_s,
      name: item['name'],
      description: item['description'],
      price: item['price'].to_f,
      currency: 'VND',
      sku: item['code'],
      barcode: item['barcode'],
      status: item['status'] == 'Active' ? 'active' : 'draft',
      variants: []
    }
  end
end
