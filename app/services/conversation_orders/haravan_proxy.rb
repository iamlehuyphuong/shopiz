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
