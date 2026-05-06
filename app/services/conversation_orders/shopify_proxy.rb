# Proxy for Shopify Order API.
# Uses the ShopifyAPI gem (REST Admin client).
class ConversationOrders::ShopifyProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::ShopifyClient

  def create_order(payload)
    shopify_post('orders.json', { order: payload })
  end

  def fetch_order(order_id)
    result = shopify_get("orders/#{order_id}.json")
    result&.dig('order')
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
end
