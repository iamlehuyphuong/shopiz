# Proxy for TikTok Shop Order API.
# TikTok Shop does NOT support creating orders via API — orders come from the marketplace.
# This proxy only supports fetching/syncing existing orders.
class ConversationOrders::TiktokShopProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::TiktokShopClient

  def create_order(_payload)
    # TikTok Shop orders are created by buyers on the marketplace.
    # We cannot push new orders via API.
    nil
  end

  def fetch_order(order_id)
    result = tiktok_shop_get('/order/202309/orders', { ids: [order_id] })
    result&.dig('data', 'orders')&.first
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
end
