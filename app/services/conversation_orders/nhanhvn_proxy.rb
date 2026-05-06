# Proxy for Nhanh.vn Order API.
# Nhanh.vn uses POST-only endpoints with form-encoded data.
class ConversationOrders::NhanhvnProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::NhanhvnClient

  def create_order(payload)
    nhanhvn_post('/api/order/add', payload)
  end

  def fetch_order(order_id)
    result = nhanhvn_post('/api/order/detail', { id: order_id })
    result&.dig('data')
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
end
