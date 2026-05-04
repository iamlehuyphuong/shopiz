# Proxy for Sapo Order API.
# Sapo REST Admin API: POST /admin/orders.json, GET /admin/orders/{id}.json
class ConversationOrders::SapoProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::SapoClient

  def create_order(payload)
    sapo_post('orders.json', { order: payload })
  end

  def fetch_order(order_id)
    result = sapo_get("orders/#{order_id}.json")
    result&.dig('order')
  end

  def map_status(raw_status)
    # Sapo: financial_status / fulfillment_status
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
